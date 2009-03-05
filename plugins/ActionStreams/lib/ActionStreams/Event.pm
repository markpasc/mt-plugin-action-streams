
package ActionStreams::Event;

use strict;
use base qw( MT::Object MT::Taggable MT::Scorable );
our @EXPORT_OK = qw( classes_for_type );
use HTTP::Date qw( str2time );

use MT::Util qw( encode_html encode_url );
use MT::I18N;

use ActionStreams::Scraper;

our $hide_timeless = 0;

__PACKAGE__->install_properties({
    column_defs => {
        id         => 'integer not null auto_increment',
        identifier => 'string(200)',
        author_id  => 'integer not null',
        visible    => 'integer not null',
    },
    defaults => {
        visible => 1,
    },
    indexes => {
        identifier => 1,
        author_id  => 1,
        created_on => 1,
        created_by => 1,
    },
    class_type  => 'event',
    audit       => 1,
    meta        => 1,
    datasource  => 'profileevent',
    primary_key => 'id',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        title
        url
        thumbnail
        via
        via_id
    ) ],
});

# Oracle does not like an identifier of more than 30 characters.
sub datasource {
    my $class = shift;
    my $r = MT->request;
    my $ds = $r->cache('as_event_ds');
    return $ds if $ds;
    my $dss_oracle = qr/(db[id]::)?oracle/;
    if ( my $type = MT->config('ObjectDriver') ) {
        if ((lc $type) =~ m/^$dss_oracle$/) {
            $ds = 'as';
        }
    }
    $ds = $class->properties->{datasource}
        unless $ds;
    $r->cache('as_event_ds', $ds);
    return $ds;
}

sub encode_field_for_html {
    my $event = shift;
    my ($field) = @_;
    return encode_html( $event->$field() );
}

sub as_html {
    my $event = shift;
    my %params = @_;
    my $stream = $event->registry_entry or return '';

    # How many spaces are there in the form?
    my $form = $params{form} || $stream->{html_form} || q{};
    my @nums = $form =~ m{ \[ _ (\d+) \] }xmsg;
    my $max = shift @nums;
    for my $num (@nums) {
        $max = $num if $max < $num;
    }

    # Do we need to supply the author name?
    my @content = map { $event->encode_field_for_html($_) }
        @{ $stream->{html_params} };
    if ($max > scalar @content) {
        my $name = defined $params{name} ? $params{name}
                 :                         $event->author->nickname
                 ;
        unshift @content, encode_html($name);
    }

    return MT->translate($form, @content);
}

sub update_events_loggily {
    my $class = shift;
    my %profile = @_;

    # Keep this option out of band so we don't have to count on
    # implementations of update_events() passing it through.
    local $hide_timeless = delete $profile{hide_timeless} ? 1 : 0;

    my $warn = $SIG{__WARN__} || sub { print STDERR $_[0] };
    local $SIG{__WARN__} = sub {
        my ($msg) = @_;
        $msg =~ s{ \n \z }{}xms;
        $msg = MT->component('ActionStreams')->translate(
            '[_1] updating [_2] events for [_3]',
            $msg, $profile{type}, $profile{author}->name,
        );
        $warn->("$msg\n");
    };

    eval {
        $class->update_events(%profile);
    };

    if (my $err = $@) {
        my $plugin = MT->component('ActionStreams');
        my $err_msg = $plugin->translate("Error updating events for [_1]'s [_2] stream (type [_3] ident [_4]): [_5]",
            $profile{author}->name, $class->properties->{class_type},
            $profile{type}, $profile{ident}, $err);
        MT->log($err_msg);
        die $err;  # re-throw so we can handle from job invocation
    }
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my $author = delete $profile{author};

    my $stream = $class->registry_entry or return;
    my $fetch = $stream->{fetch} || {};

    local $profile{url} = $stream->{url};
    die "Oops, no url?" if !$profile{url};
    die "Oops, no ident?" if !$profile{ident};
    require MT::I18N;
    my $ident = encode_url(MT::I18N::encode_text($profile{ident}, undef, 'utf-8'));
    $profile{url} =~ s/ {{ident}} / $ident /xmsge;

    my $items;
    if (my $xpath_params = $stream->{xpath}) {
        $items = $class->fetch_xpath(
            %$xpath_params,
            %$fetch,
            %profile,
        );
    }
    elsif (my $atom_params = $stream->{atom}) {
        my $get = {
            created_on  => 'published',
            modified_on => 'updated',
            title       => 'title',
            url         => q{link[@rel='alternate']/@href},
            via         => q{link[@rel='alternate']/@href},
            via_id      => 'id',
            identifier  => 'id',
        };
        $atom_params = {} if !ref $atom_params;
        @$get{keys %$atom_params} = values %$atom_params;

        $items = $class->fetch_xpath(
            foreach => '//entry',
            get => $get,
            %$fetch,
            %profile
        );

        for my $item (@$items) {
            if ($item->{modified_on} && !$item->{created_on}) {
                $item->{created_on} = $item->{modified_on};
            }
        }
    }
    elsif (my $rss_params = $stream->{rss}) {
        my $get = {
            title      => 'title',
            url        => 'link',
            via        => 'link',
            created_on => 'pubDate',
            thumbnail  => 'media:thumbnail/@url',
            via_id     => 'guid',
            identifier => 'guid',
        };
        $rss_params = {} if !ref $rss_params;
        @$get{keys %$rss_params} = values %$rss_params;

        $items = $class->fetch_xpath(
            foreach => '//item',
            get => $get,
            %$fetch,
            %profile
        );

        for my $item (@$items) {
            if ($item->{modified_on} && !$item->{created_on}) {
                $item->{created_on} = $item->{modified_on};
            }
        }
    }
    elsif (my $scraper_params = $stream->{scraper}) {
        my ($foreach, $get) = @$scraper_params{qw( foreach get )};
        my $scraper = scraper {
            process $foreach, 'res[]' => scraper {
                while (my ($field, $sel) = each %$get) {
                    process $sel->[0], $field => $sel->[1];
                }
            };
            result 'res';
        };

        $items = $class->fetch_scraper(
            scraper => $scraper,
            %$fetch,
            %profile,
        );
    }
    return if !$items;

    $class->build_results(
        items   => $items,
        stream  => $stream,
        author  => $author,
        profile => \%profile,
    );
}

sub registry_entry {
    my $event = shift;
    my ($type, $stream) = split /_/, $event->properties->{class_type}, 2;

    my $reg = MT->instance->registry('action_streams') or return;
    my $service = $reg->{$type} or return;
    $service->{$stream};
}

sub author {
    my $event = shift;
    my $author_id = $event->author_id
        or return;
    return MT->instance->model('author')->lookup($author_id);
}

sub blog_id { 0 }

sub classes_for_type {
    my $class = shift;
    my ($type) = @_;

    my $prevts = MT->instance->registry('action_streams');
    my $prevt = $prevts->{$type};
    return if !$prevt;

    my @classes;
    PACKAGE: while (my ($stream_id, $stream) = each %$prevt) {
        next if 'HASH' ne ref $stream;
        next if !$stream->{class} && !$stream->{url};

        my $pkg;
        if ($pkg = $stream->{class}) {
            $pkg = join q{::}, $class, $pkg if $pkg && $pkg !~ m{::}xms;
            if (!eval { $pkg->properties }) {
                if (!eval "require $pkg; 1") {
                    my $error = $@ || q{};
                    my $pl = MT->component('ActionStreams');
                    MT->log($pl->translate('Could not load class [_1] for stream [_2] [_3]: [_4]',
                        $pkg, $type, $stream_id, $error));
                    next PACKAGE;
                }
            }
        }
        else {
            $pkg = join q{::}, $class, 'Auto', ucfirst $type,
                ucfirst $stream_id;
            if (!eval { $pkg->properties }) {
                eval "package $pkg; use base qw( $class ); 1" or next;

                my $class_type = join q{_}, $type, $stream_id;
                $pkg->install_properties({ class_type => $class_type });
                $pkg->install_meta({ columns => $stream->{fields} })
                    if $stream->{fields};
            }
        }
        push @classes, $pkg;
    }

    return @classes;
}

my $ua;

sub ua {
    my $class = shift;
    my %params = @_;

    $ua ||= MT->new_ua({
        paranoid => 1,
        timeout  => 10,
    });

    $ua->max_size(250_000) if $ua->can('max_size');
    $ua->agent($params{default_useragent} ? $ua->_agent
        : "mt-actionstreams-lwp/" . MT->component('ActionStreams')->version);

    return $ua if $class->class_type eq 'event';
    return $ua if $params{unconditional};

    require ActionStreams::UserAgent::Adapter;
    my $adapter = ActionStreams::UserAgent::Adapter->new(
        ua                  => $ua,
        action_type         => $class->class_type,
        die_on_not_modified => $params{die_on_not_modified} || 0,
    );
    return $adapter;
}

sub set_values {
    my $event = shift;
    my ($values) = @_;

    for my $meta_col (keys %{ $event->properties->{meta_columns} || {} }) {
        my $meta_val = delete $values->{$meta_col};
        $event->$meta_col($meta_val) if defined $meta_val;
    }

    $event->SUPER::set_values($values);
}

sub fetch_xpath {
    my $class = shift;
    my %params = @_;

    my $url = $params{url} || '';
    if (!$url) {
        MT->log(
            MT->component('ActionStreams')->translate(
                "No URL to fetch for [_1] results", $class));
        return;
    }
    my $ua = $class->ua(%params);
    my $res = $ua->get($url);
    if (!$res->is_success()) {
        MT->log(
            MT->component('ActionStreams')->translate(
                "Could not fetch [_1]: [_2]", $url, $res->status_line()))
            if $res->code != 304;
        return;
    }
    # Do not continue if contents is incomplete.
    if (my $abort = $res->{_headers}{'client-aborted'}) {
        MT->log(
            MT->component('ActionStreams')->translate(
                'Aborted fetching [_1]: [_2]', $url, $abort));
        return;
    }

    # Strip leading whitespace, since the parser doesn't like it.
    # TODO: confirm we got xml?
    my $content = $res->content;
    $content =~ s{ \A \s+ }{}xms;

    require XML::XPath;
    my $x = XML::XPath->new( xml => $content );

    my @items;
    ITEM: for my $item ($x->findnodes($params{foreach})) {
        my %item_data;
        VALUE: while (my ($key, $val) = each %{ $params{get} }) {
            next VALUE if !$val;
            if ($key eq 'tags') {
                my @outvals = $item->findnodes($val)
                    or next VALUE;

                $item_data{$key} = [ map { MT::I18N::utf8_off( $_->getNodeValue ) } @outvals ];
            }
            else {
                my $outval = $item->findvalue($val)
                    or next VALUE;

                $outval = MT::I18N::utf8_off("$outval");
                if ($outval && ($key eq 'created_on' || $key eq 'modified_on')) {
                    # try both RFC 822/1123 and ISO 8601 formats
                    $outval = MT::Util::epoch2ts(undef, str2time($outval))
                        || MT::Util::iso2ts(undef, $outval);
                }

                $item_data{$key} = $outval if $outval;
            }
        }
        push @items, \%item_data;
    }

    return \@items;
}

sub build_results {
    my $class = shift;
    my %params = @_;

    my ($author, $items, $profile, $stream) =
        @params{qw( author items profile stream )};

    my $mt = MT->app;
    ITEM: for my $item (@$items) {
        my $event;

        my $identifier = delete $item->{identifier};
        if (!defined $identifier && (defined $params{identifier} || defined $stream->{identifier})) {
            $identifier = join q{:}, @$item{ split /,/, $params{identifier} || $stream->{identifier} };
        }
        if (defined $identifier) {
            $identifier = "$identifier";
            ($event) = $class->search({
                author_id  => $author->id,
                identifier => $identifier,
            });
        }

        $event ||= $class->new;

        $mt->run_callbacks('pre_build_action_streams_event.'
            . $class->class_type, $mt, $item, $event, $author, $profile);

        my $tags = delete $item->{tags};
        $event->set_values({
            author_id  => $author->id,
            identifier => $identifier,
            %$item,
        });
        $event->tags(@$tags) if $tags;
        if ($hide_timeless && !$event->created_on) {
            $event->visible(0);
        }

        $mt->run_callbacks('post_build_action_streams_event.'
            . $class->class_type, $mt, $item, $event, $author, $profile);

        $event->save() or MT->log($event->errstr);
    }

    1;
}

sub save {
    my $event = shift;

    # Built-in audit field setting will set a local time, so do it ourselves.
    if (!$event->created_on) {
        my $ts = MT::Util::epoch2ts(undef, time);
        $event->created_on($ts);
        $event->modified_on($ts);
    }

    return $event->SUPER::save(@_);
}

sub fetch_scraper {
    my $class = shift;
    my %params = @_;
    my ($url, $scraper) = @params{qw( url scraper )};

    $scraper->user_agent( $class->ua( %params, die_on_not_modified => 1 ) );
    my $uri_obj = URI->new($url);
    my $items = eval { $scraper->scrape($uri_obj) };

    # Ignore Web::Scraper errors due to 304 Not Modified responses.
    if (!$items && $@ && !UNIVERSAL::isa($@, 'ActionStreams::UserAgent::NotModified')) {
        die;  # rethrow
    }

    # we're only being used for our scraper.
    return if !$items;
    return $items if !ref $items;
    return $items if 'ARRAY' ne ref $items;

    ITEM: for my $item (@$items) {
        next ITEM if !ref $item || ref $item ne 'HASH';
        for my $field (keys %$item) {
            if ($field eq 'tags') {
                $item->{$field} = [ map { MT::I18N::utf8_off( "$_" ) } @{ $item->{$field} } ];
            }
            else {
                $item->{$field} = MT::I18N::utf8_off( q{} . $item->{$field} );
            }
        }
    }

    return $items;
}

sub backup_terms_args {
    my $class = shift;
    my ($blog_ids) = @_;
    return { terms => { 'class' => '*' }, args => undef };
}

1;

__END__

=head1 NAME

ActionStreams::Event - an Action Streams stream definition

=head1 SYNOPSIS

    # in plugin's config.yaml
    
    profile_services:
        example:
            streamid:
                name:  Dice Example
                description: A simple die rolling Perl stream example.
                html_form: [_1] rolled a [_2]!
                html_params:
                    - title
                class: My::Stream

    # in plugin's lib/My/Stream.pm

    package My::Stream;
    use base qw( ActionStreams::Event );
    
    __PACKAGE__->install_properties({
        class_type => 'example_streamid',
    });
    
    sub update_events {
        my $class = shift;
        my %profile = @_;
        
        # trivial example: save a random number
        my $die_roll = int rand 20;
        my %item = (
            title      => $die_roll,
            identifier => $die_roll,
        );
        
        return $class->build_results(
            author => $profile{author},
            items  => [ \%item ],
        );
    }
    
    1;

=head1 DESCRIPTION

I<ActionStreams::Event> provides the basic implementation of an action stream.
Stream definitions are engines for turning web resources into I<actions> (also
called I<events>). This base class produces actions based on generic stream
recipes defined in the MT registry, as well as providing the internal machinery
for you to implement your own streams in Perl code.

=head1 METHODS TO IMPLEMENT

These are the methods one commonly implements (overrides) when implementing a
stream subclass.

=head2 C<$class-E<gt>update_events(%profile)>

Fetches the web resource specified by the profile parameters, collects data
from it into actions, and saves the action records for use later. Required
members of C<%profile> are:

=over 4

=item * C<author>

The C<MT::Author> instance for whom events should be collected.

=item * C<ident>

The author's identifier on the given service.

=back

Other information about the stream, such as the URL pattern into which the
C<ident> parameter can be replaced, is available through the
C<$class-E<gt>registry_entry()> method.

=head2 C<$self-E<gt>as_html(%params)>

Returns the HTML version of the action, suitable for display to readers.

The default implementation uses the stream's registry definition to construct
the action: the author's name and the action's values as named in
C<html_params> are replaced into the stream's C<html_form> setting. You need
override it only if you have more complex requirements.

Optional members of C<%params> are:

=over 4

=item * C<form>

The formatting string to use. If not given, the C<html_form> specified for
this stream in the registry is used.

=item * C<name>

The text to use as the author's name if C<as_html> needs to provide it
automatically in the result. Author names are provided if there are more
tokens in C<html_form> than there are fields specified in C<html_params>.

If not given, the event's author's nickname is provided. Note that a defined
but empty name (such as C<q{}>) I<will> be used; in this case, the name will
appear to be omitted from the result of the C<as_html> call.

=back

=head1 AVAILABLE METHODS

These are the methods provided by I<ActionStreams::Event> to perform common
tasks. Call them from your overridden methods.

=head2 C<$self-E<gt>set_values(\%values)>

Stores the data given in C<%values> as members of this event.

=head2 C<$class-E<gt>fetch_xpath(%param)>

Returns the items discovered by scanning a web resource by the given XPath
recipe. Required members of C<%param> are:

=over 4

=item * C<url>

The address of the web resource to scan for events. The resource should be a
valid XML document.

=item * C<foreach>

The XPath selector with which to select the individual events from the
resource.

=item * C<get>

A hashref containing the XPath selectors with which to collect individual data
for each item, keyed on the names of the fields to contain the data.

=back

C<%param> may also contain additional arguments for the C<ua()> method.

Returned items are hashrefs containing the discovered fields, suitable for
turning into C<ActionStreams::Event> records with the C<build_results()>
method.

=head2 C<$class-E<gt>fetch_scraper(%param)>

Returns the items discovered by scanning by the given recipe. Required members
of C<%param> are:

=over 4

=item * C<url>

The address of the web resource to scan for events. The resource should be an
HTML or XML document suitable for analysis by the C<Web::Scraper> module.

=item * C<scraper>

The C<Web::Scraper> scraper with which to extract item data from the specified
web resource. See L<Web::Scraper> for information on how to construct a
scraper.

=back

Returned items are hashrefs containing the discovered fields, suitable for
turning into C<ActionStreams::Event> records with the C<build_results()>
method.

See also the below I<NOTE ON WEB::SCRAPER>.

=head2 C<$class-E<gt>build_results(%param)>

Converts a set of collected items into saved action records of type C<$class>.
The required members of C<%param> are:

=over 4

=item * C<author>

The C<MT::Author> instance whose action the items represent.

=item * C<items>

An arrayref of items to save as actions. Each item is a hashref containing the
action data, keyed on the names of the fields containing the data.

=back

Optional parameters are:

=over 4

=item * C<profile>

An arrayref describing the data for the author's profile for the associated
stream, such as is returned by the C<MT::Author::other_profile()> method
supplied by the Action Streams plugin.

The profile member is not used directly by C<build_results()>; they are only
passed to callbacks.

=item * C<stream>

A hashref containing the settings from the registry about the stream, such as
is returned from the C<registry_entry()> method.

=back

=head2 C<$class-E<gt>ua(%param)>

Returns the common HTTP user-agent, an instance of C<LWP::UserAgent>, with
which you can fetch web resources.

The resulting user agent may provide automatic conditional HTTP support when
you call its C<get> method. A UA with conditional HTTP support enabled will
store the values of the conditional HTTP headers (C<ETag> and
C<Last-Modified>) received in responses as C<ActionStreams::UserAgent::Cache>
objects and, on subsequent requests of the same URL, automatically supply the
header values. When the remote HTTP server reports that such a resource has
not changed, the C<HTTP::Response> will be a C<304 Not Modified> response; the
user agent does not itself store and supply the resource content. Using other
C<LWP::UserAgent> methods such as C<post> or C<request> will I<not> trigger
automatic conditional HTTP support.

No arguments are required; possible optional parameters are:

=over 4

=item * C<default_useragent>

If set, the returned HTTP user-agent will use C<LWP::UserAgent>'s default
identifier in the HTTP C<User-Agent> header. If omitted, the UA will use the
Action Streams identifier of C<mt-actionstreams-lwp/I<version>>.

=item * C<unconditional>

If set, the return HTTP user-agent will I<not> automatically use conditional
HTTP to avoid requesting old content from compliant servers. That is, if
omitted, the UA I<will> automatically use conditional HTTP when you call its
C<get> method.

=item * C<die_on_not_modified>

If set, when the response of the HTTP user-agent's C<get> method is a
conditional HTTP C<304 Not Modified> response, throw an exception instead of
returning the response. (Use this option to return control to yourself when
passing UAs with conditional HTTP support to other Perl modules that don't
expect 304 responses.)

The thrown exception is an C<ActionStreams::UserAgent::NotModified> exception.

=back

=head2 C<$self-E<gt>author()>

Returns the C<MT::Author> instance associated with this event, if its
C<author_id> field has been set.

=head2 C<$class-E<gt>install_properties(\%properties)>

I<TODO>

=head2 C<$class-E<gt>install_meta(\%properties)>

I<TODO>

=head2 C<$class-E<gt>registry_entry()>

Returns the registry data for the stream represented by C<$class>.

=head2 C<$class-E<gt>classes_for_type($service_id)>

Given a profile service ID (that is, a key from the C<profile_services> section
of the registry), returns a list of stream classes for scanning that service's
streams.

=head2 C<$class-E<gt>backup_terms_args($blog_ids)>

Used in backup.  Backup function calls the method to generate $terms and
$args for the class to load objects.  ActionStream::Event does not have
blog_id and does use class_column, the nature the class has to tell
backup function to properly load all the target objects of the class
to be backed up. 

See I<MT::BackupRestore> for more detail.

=head1 NOTE ON WEB::SCRAPER

The C<Web::Scraper> module is powerful, but it has complex dependencies. While
its pure Perl requirements are bundled with the Action Streams plugin, it also
requires a compiled XML module. Also, because of how its syntax works, you must
directly C<use> the module in your own code, contrary to the Movable Type idiom
of using C<require> so that modules are loaded only when they are sure to be
used.

If you attempt load C<Web::Scraper> in the normal way, but C<Web::Scraper> is
unable to load due to its missing requirement, whenever the plugin attempts to
load your scraper, the entire plugin will fail to load.

Therefore the C<ActionStreams::Scraper> wrapper module is provided for you. If
you need to load C<Web::Scraper> so as to make a scraper to pass
C<ActionStreams::Event::fetch_scraper()> method, instead write in your module:

    use ActionStreams::Scraper;

This module provides the C<Web::Scraper> interface, but if C<Web::Scraper> is
unable to load, the error will be thrown when your module tries to I<use> it,
rather than when you I<load> it. That is, if C<Web::Scraper> can't load, no
errors will be thrown to end users until they try to use your stream.

=head1 AUTHOR

Mark Paschal E<lt>mark@sixapart.comE<gt>

=cut

