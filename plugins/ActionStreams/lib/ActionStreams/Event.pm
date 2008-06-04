
package ActionStreams::Event;

use strict;
use base qw( MT::Object MT::Taggable MT::Scorable );
our @EXPORT_OK = qw( classes_for_type );
use Web::Scraper;
use HTTP::Date qw( str2time );

our $hide_if_first_update = 0;

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
    ) ],
});

sub as_html {
    my $event = shift;
    my $stream = $event->registry_entry or return '';
    return MT->translate($stream->{html_form} || '',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } @{ $stream->{html_params} });
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
    $profile{url} =~ s/ {{ident}} / $profile{ident} /xmsge;

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
            created_on => 'published/child::text()',
            modified_on => 'updated/child::text()',
            title => 'title/child::text()',
            url => q{link[@rel='alternate']/@href},
            identifier => 'id/child::text()',
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
    elsif (my $rss_params - $stream->{rss}) {
        my $get = {
            title => 'title/child::text()',
            url => 'link/child::text()',
            created_on => 'pubDate/child::text()',
            identifier => 'guid/child::text()',
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
    while (my ($stream_id, $stream) = each %$prevt) {
        next if 'HASH' ne ref $stream;
        next if !$stream->{class} && !$stream->{url};
    
        my $pkg;
        if ($pkg = $stream->{class}) {
            $pkg = join q{::}, $class, $pkg if $pkg && $pkg !~ m{::}xms;
            if (!eval { $pkg->properties }) {
                eval "require $pkg; 1" or next;
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

    if (!$ua) {
        my %agent_params = ();
        my @classes = (qw( LWPx::ParanoidAgent LWP::UserAgent ));
        while (my $maybe_class = shift @classes) {
            if (eval "require $maybe_class; 1") {
                $ua = $maybe_class->new(%agent_params);
                $ua->timeout(10);
                last;
            }
        }
    }

    $ua->agent($params{default_useragent} ? $ua->_agent
        : "mt-actionstreams-lwp/" . MT->component('ActionStreams')->version);
    return $ua;
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
        MT->log("No URL to fetch for $class results");
        return;
    }
    my $ua = $class->ua(%params);
    my $res = $ua->get($url);
    if (!$res->is_success()) {
        MT->log("Could not fetch ${url}: " . $res->status_line());
        return;
    }

    # TODO: confirm we got xml?

    require XML::XPath;
    my $x = XML::XPath->new( xml => $res->content );

    my @items;
    ITEM: for my $item ($x->findnodes($params{foreach})) {
        my %item_data;
        VALUE: while (my ($key, $val) = each %{ $params{get} }) {
            next VALUE if !$val;
            if ($key eq 'tags') {
                my @outvals = $item->findnodes($val)
                    or next VALUE;
                    
                $item_data{$key} = [ map { $_->getNodeValue } @outvals ];
            }
            else {
                my $outval = $item->findvalue($val)
                    or next VALUE;

                $outval = "$outval";
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
        if ($hide_if_first_update && !$event->created_on) {
            $event->visible(0);
        }

        $mt->run_callbacks('post_build_action_streams_event.'
            . $class->class_type, $mt, $item, $event, $author, $profile);
        
        $event->save() or MT->log($event->errstr);
    }

    1;
}

sub fetch_scraper {
    my $class = shift;
    my %params = @_;
    my ($url, $scraper) = @params{qw( url scraper )};

    $scraper->user_agent($class->ua(%params));
    my $items = $scraper->scrape(URI->new($url));

    for my $item (@$items) {
        for my $field (keys %$item) {
            if ($field eq 'tags') {
                $item->{$field} = [ map { "$_" } @{ $item->{$field} } ];
            }
            else {
                $item->{$field} = q{} . $item->{$field};
            }
        }
    }
    
    return $items;
}

__PACKAGE__->add_trigger( post_save => sub {
    my ($obj, $orig_obj) = @_;
    MT->request('saved_action_stream_events', 1);
} );

1;

