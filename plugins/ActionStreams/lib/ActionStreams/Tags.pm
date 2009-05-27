package ActionStreams::Tags;

use strict;

use MT::Util qw( offset_time_list epoch2ts ts2epoch );
use ActionStreams::Plugin;

sub stream_action {
    my ($ctx, $args, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamAction in a non-action-stream context!");
    return $event->as_html(
        defined $args->{name} ? (name => $args->{name}) : ()
    );
}

sub stream_action_id {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionURL in a non-action-stream context!");
    return $event->id || '';
}

sub stream_action_var {
    my ($ctx, $arg, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionVar in a non-action-stream context!");
    my $var = $arg->{var} || $arg->{name}
        or return $ctx->error("Used StreamActionVar without a 'name' attribute!");
    return $ctx->error("Use StreamActionVar to retrieve invalid variable $var from event of type " . ref $event)
        if !$event->can($var) && !$event->has_column($var);
    return $event->$var();
}

sub stream_action_date {
    my ($ctx, $arg, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionDate in a non-action-stream context!");
    my $c_on = $event->created_on;
    local $arg->{ts} = epoch2ts( $ctx->stash('blog'), ts2epoch(undef, $c_on) )
        if $c_on;
    return $ctx->_hdlr_date($arg);
}

sub stream_action_modified_date {
    my ($ctx, $arg, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionModifiedDate in a non-action-stream context!");
    my $m_on = $event->modified_on || $event->created_on;
    local $arg->{ts} = epoch2ts( $ctx->stash('blog'), ts2epoch(undef, $m_on) )
        if $m_on;
    return $ctx->_hdlr_date($arg);
}

sub stream_action_title {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionTitle in a non-action-stream context!");
    return $event->title || '';
}

sub stream_action_url {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionURL in a non-action-stream context!");
    return $event->url || '';
}

sub stream_action_thumbnail_url {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionThumbnailURL in a non-action-stream context!");
    return $event->thumbnail || '';
}

sub stream_action_via {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionVia in a non-action-stream context!");
    return $event->via || q{};
}

sub other_profile_var {
    my( $ctx, $args ) = @_;
    my $profile = $ctx->stash( 'other_profile' )
        or return '';
    my $var = $args->{name} || 'uri';
    return defined $profile->{ $var } ? $profile->{ $var } : '';
}

sub _author_ids_for_args {
    my ($ctx, $args, $cond) = @_;

    my @author_ids;
    if (my $ids = $args->{author_ids} || $args->{author_id}) {
        @author_ids = split /\s*,\s*/, $ids;
    }
    elsif (my $disp_names = $args->{display_names} || $args->{display_name}) {
        my @names = split /\s*,\s*/, $disp_names;
        my @authors = MT->model('author')->load({ nickname => \@names });
        @author_ids = map { $_->id } @authors;
    }
    elsif (my $names = $args->{author} || $args->{authors}) {
        # If arg is the special string 'all', then include all authors by returning undef instead of an empty array.
        return if $names =~ m{ \A\s* all \s*\z }xmsi;

        my @names = split /\s*,\s*/, $names;
        my @authors = MT->model('author')->load({ name => \@names });
        @author_ids = map { $_->id } @authors;
    }
    elsif (my $author = $ctx->stash('author')) {
        @author_ids = ( $author->id );
    }
    elsif (my $blog = $ctx->stash('blog')) {
        my @authors = MT->model('author')->load({
            status => 1,  # enabled
        }, {
            join => MT->model('permission')->join_on('author_id',
                { blog_id => $blog->id }, { unique => 1 }),
        });
        my $blog_id = $ctx->stash('blog_id');
        my $blog = MT->model('blog')->load( $blog_id );
        if ( $args->{no_commenter} ) {
            @author_ids = map { $_->[0]->id }
                grep { $_->[1]->can_administer_blog || $_->[1]->can_create_post }
                map  { [ $_, $_->permissions($blog->id) ] }
                @authors;
        }
        elsif ( $blog->publish_authd_untrusted_commenters ) {
            @author_ids = map { $_->[0]->id }
                grep {
                    $_->[1]->can_administer_blog
                    || $_->[1]->can_create_post
                    || $_->[1]->has('comment')
                    || ( $_->[0]->type == MT::Author::COMMENTER()
                        && !$_->[0]->is_banned($blog_id) )
                }
                map  { [ $_, $_->permissions($blog->id) ] }
                @authors;
        }
        else {
            @author_ids = map { $_->[0]->id }
                grep {
                    $_->[1]->can_administer_blog
                    || $_->[1]->can_create_post
                    || $_->[1]->has('comment')
                }
                map  { [ $_, $_->permissions($blog->id) ] }
                @authors;
        }
    }

    return \@author_ids;
}

sub action_streams {
    my ($ctx, $args, $cond) = @_;

    my %terms = (
        class     => '*',
        visible   => 1,
    );
    my $author_id = _author_ids_for_args(@_);
    $terms{author_id} = $author_id if defined $author_id;
    my %args = (
        sort      => ($args->{sort_by}   || 'created_on'),
        direction => ($args->{direction} || 'descend'),
    );

    my $app = MT->app;
    undef $app unless $app->isa('MT::App');

    if (my $limit = $args->{limit} || $args->{lastn}) {
        $args{limit} = $limit eq 'auto' ? ( $app ? $app->param('limit') : 20 ) : $limit;
        $args{limit} = 20 unless $args{limit};
    }
    elsif (my $days = $args->{days}) {
        my @ago = offset_time_list(time - 3600 * 24 * $days,
            $ctx->stash('blog'));
        my $ago = sprintf "%04d%02d%02d%02d%02d%02d",
            $ago[5]+1900, $ago[4]+1, @ago[3,2,1,0];
        $terms{created_on} = [ $ago ];
        $args{range_incl}{created_on} = 1;
    }
    else {
        $args{limit} = 20;
    }

    if (my $offset = $args->{offset}) {
        if ($offset eq 'auto') {
            if ( $app && $app->param('offset') ) {
                $offset = $app->param('offset') || 0;
            }
            else {
                $offset = 0;
            }
        }
        if ($offset =~ m/^\d+$/) {
            $args{offset} = $offset;
        }
    }

    my ($service, $stream) = @$args{qw( service stream )};
    if ($service && $stream) {
        $terms{class} = join q{_}, $service, $stream;
    }
    elsif ($service) {
        $terms{class} = $service . '_%';
        $args{like} = { class => 1 };
    }
    elsif ($stream) {
        $terms{class} = '%_' . $stream;
        $args{like} = { class => 1 };
    }

    # Make sure all classes are loaded.
    require ActionStreams::Event;
    for my $service (keys %{ MT->instance->registry('action_streams') || {} }) {
        ActionStreams::Event->classes_for_type($service);
    }

    my @events = ActionStreams::Event->search(\%terms, \%args);
    my $number_of_events = $ctx->stash('count');
    $number_of_events = ActionStreams::Event->count(\%terms, \%args)
        unless defined $number_of_events;
    return $ctx->_hdlr_pass_tokens_else($args, $cond)
        if !@events;
    if ($args{sort} eq 'created_on') {
        @events = sort { $b->created_on cmp $a->created_on || $b->id <=> $a->id } @events;
        @events = reverse @events
            if $args{direction} ne 'descend';
    }
    local $ctx->{__stash}{remaining_stream_actions} = \@events;


    my $res = '';
    my ($count, $total) = (0, scalar @events);
    my $day_date = '';

    # For pagination tags
    my ( $l, $o, $c ); 
    if ( exists $ctx->{__stash}{limit} ) {
        $l = $ctx->{__stash}{limit};
    }
    elsif ( exists $args{limit} ){
        $l = $args{limit};
    }
    local $ctx->{__stash}{limit}  = $l if defined $l;
    if ( exists $ctx->{__stash}{offset} ) {
        $o = $ctx->{__stash}{offset};
    }
    elsif ( exists $args{offset} ){
        $o = $args{offset};
    }
    local $ctx->{__stash}{offset}  = $o if defined $o;
    if ( exists $ctx->{__stash}{count} ) {
        $c = $ctx->{__stash}{count};
    }
    else {
        $c = $number_of_events;
    }
    local $ctx->{__stash}{count} = $c if defined $c;
    $ctx->{__stash}{number_of_events} = $number_of_events;

    EVENT: while (my $event = shift @events) {
        my $new_day_date = _event_day($ctx, $event);
        local $cond->{DateHeader} = $day_date ne $new_day_date ? 1 : 0;
        local $cond->{DateFooter} = !@events                                      ? 1
                                  : $new_day_date ne _event_day($ctx, $events[0]) ? 1
                                  :                                                 0
                                  ;
        $day_date = $new_day_date;

        $count++;
        defined (my $out = _build_about_event(
            $ctx, $args, $cond,
            event => $event,
            count => $count,
            total => $total,
        )) or return;
        $res .= $out;
    }

    return $res;
}

sub _build_about_event {
    my ($ctx, $arg, $cond, %param) = @_;
    my ($event, $count, $total) = @param{qw( event count total )};

    local $ctx->{__stash}{stream_action} = $event;
    my $author = $event->author;
    local $ctx->{__stash}{author} = $event->author;

    my $type = $event->class_type;
    my ($service, $stream_id) = split /_/, $type, 2;
    my $profile = $author->other_profiles($service);
    $profile = $profile->[0]
        if ( defined $profile && 'ARRAY' eq ref $profile );
    local $ctx->{__stash}{other_profile} = $profile;

    my $vars = $ctx->{__stash}{vars} ||= {};
    local $vars->{action_type} = $type;
    local $vars->{service_type} = $service;
    local $vars->{stream_type} = $stream_id;

    local $vars->{__first__}   = $count == 1;
    local $vars->{__last__}    = $count == $total;
    local $vars->{__odd__}     = ($count % 2) == 1;
    local $vars->{__even__}    = ($count % 2) == 0;
    local $vars->{__counter__} = $count;

    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');

    defined(my $out = $builder->build($ctx, $tokens, $cond))
        or return $ctx->error($builder->errstr);
    return $out;
}

sub stream_action_rollup {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionRollup in a non-action-stream context!");
    my $nexts = $ctx->stash('remaining_stream_actions');
    return $ctx->else($arg, $cond)
        if !$nexts || !@$nexts;

    my $by_spec = $arg->{by} || 'date,action';
    my %by = map { $_ => 1 } split /\s*,\s*/, $by_spec;

    my $event_date  = _event_day($ctx, $event);
    my $event_class = $event->class;
    my ($event_service, $event_stream) = split /_/, $event_class, 2;

    my @rollup_events = ($event);
    EVENT: while (@$nexts) {
        my $next = $nexts->[0];
        last EVENT if $by{date}    && $event_date  ne _event_day($ctx, $next);
        last EVENT if $by{action}  && $event_class ne $next->class;
        last EVENT if $by{stream}  && $next->class !~ m{ _ \Q$event_stream\E \z }xms;
        last EVENT if $by{service} && $next->class !~ m{ \A \Q$event_service\E _ }xms;

        # Eligible to roll up! Remove it from the remaining actions.
        push @rollup_events, shift @$nexts;
    }

    return $ctx->else($arg, $cond)
        if 1 >= scalar @rollup_events;

    my $res;
    my $count = 0;
    for my $rup_event (@rollup_events) {
        $count++;
        defined (my $out = _build_about_event(
            $ctx, $arg, $cond,
            event => $rup_event,
            count => $count,
            total => scalar @rollup_events,
        )) or return;
        $res .= $arg->{glue} if $arg->{glue} && $count > 1;
        $res .= $out;
    }
    return $res;
}

sub _event_day {
    my ($ctx, $event) = @_;
    return substr(epoch2ts($ctx->stash('blog'), ts2epoch(undef, $event->created_on)), 0, 8);
}

sub stream_action_tags {
    my ($ctx, $args, $cond) = @_;

    require MT::Entry;
    my $event = $ctx->stash('stream_action');
    return '' unless $event;
    my $glue = $args->{glue} || '';

    local $ctx->{__stash}{tag_max_count} = undef;
    local $ctx->{__stash}{tag_min_count} = undef;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    my $res = '';
    my $tags = $event->get_tag_objects;
    for my $tag (@$tags) {
        next if $tag->is_private && !$args->{include_private};
        local $ctx->{__stash}{Tag} = $tag;
        local $ctx->{__stash}{tag_count} = undef;
        local $ctx->{__stash}{tag_event_count} = undef;  # ?
        defined(my $out = $builder->build($ctx, $tokens, $cond))
            or return $ctx->error( $builder->errstr );
        $res .= $glue if $res ne '';
        $res .= $out;
    }
    $res;
}

sub other_profiles {
    my( $ctx, $args, $cond ) = @_;

    my $author_ids = _author_ids_for_args(@_);
    my $author_id = shift @$author_ids
        or return $ctx->error('No author specified for OtherProfiles');
    my $user = MT->model('author')->load($author_id)
        or return $ctx->error(MT->translate('No user [_1]', $author_id));

    my @profiles = sort { lc $a->{type} cmp lc $b->{type} }
        @{ $user->other_profiles() };
    my $services = MT->app->registry('profile_services');
    if (my $filter_type = $args->{type}) {
        my $filter_except = $filter_type =~ s{ \A NOT \s+ }{}xmsi ? 1 : 0;
        @profiles = grep {
            my $profile = $_;
            my $profile_type = $profile->{type};
            my $service_type = ($services->{$profile_type} || {})->{service_type} || q{};
            $filter_except ? $service_type ne $filter_type : $service_type eq $filter_type;
        } @profiles;
    }

    my $populate_icon = sub {
        my ($item, $row) = @_;
        my $type = $item->{type};
        $row->{vars}{icon_url} = ActionStreams::Plugin->icon_url_for_service($type, $services->{$type});
    };

    return list(
        context    => $ctx,
        arguments  => $args,
        conditions => $cond,
        items      => \@profiles,
        stash_key  => 'other_profile',
        code       => $populate_icon,
    );
}

sub list {
    my %param = @_;
    my ($ctx, $args, $cond) = @param{qw( context arguments conditions )};
    my ($items, $stash_key, $code) = @param{qw( items stash_key code )};

    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');

    my $res = q{};
    my $glue = $args->{glue};
    $glue = '' unless defined $glue;
    my $vars = ($ctx->{__stash}{vars} ||= {});
    my ($count, $total) = (0, scalar @$items);
    for my $item (@$items) {
        local $ctx->{__stash}->{$stash_key} = $item;

        my $row = {};
        $code->($item, $row) if $code;
        my $lvars = delete $row->{vars} if exists $row->{vars};
        local @$vars{keys %$lvars} = values %$lvars
            if $lvars;
        local @{ $ctx->{__stash} }{keys %$row} = values %$row;

        $count++;
        my %loop_vars = (
            __first__   => $count == 1,
            __last__    => $count == $total,
            __odd__     => $count % 2,
            __even__    => !($count % 2),
            __counter__ => $count,
        );
        local @$vars{keys %loop_vars} = values %loop_vars;

        defined (my $out = $builder->build($ctx, $tokens, $cond))
            or return $ctx->error($builder->errstr);

        $res .= $glue if ($res ne '') && ($out ne '') && ($glue ne '');
        $res .= $out;
    }

    return $res;
}

sub profile_services {
    my( $ctx, $args, $cond ) = @_;

    my $app = MT->app;
    my $networks = $app->registry('profile_services');
    my @network_keys = keys %$networks;
    if ( $args->{eligible_to_add} ) {
        @network_keys = grep { !$networks->{$_}->{deprecated} } @network_keys;
        my $author = $ctx->stash('author');
        if ( $author ) {
            my $other_profiles = $author->other_profiles();
            my %has_unique_profile;
            for my $profile ( @$other_profiles ) {
                if ( !$networks->{$profile->{type}}->{can_many} ) {
                    $has_unique_profile{$profile->{type}} = 1;
                }
            }
            @network_keys = grep { !$has_unique_profile{$_} } @network_keys;
        }
    }
    @network_keys = sort { lc $networks->{$a}->{name} cmp lc $networks->{$b}->{name} }
        @network_keys;

    my $out = "";
    my $builder = $ctx->stash( 'builder' );
    my $tokens = $ctx->stash( 'tokens' );
    my $vars = ($ctx->{__stash}{vars} ||= {});
    if ($args->{extra}) {
        # Skip output completely if it's a "core" service but we want
        # extras only.
        @network_keys = grep { ! $networks->{$_}->{plugin} || ($networks->{$_}->{plugin}->id ne 'actionstreams') } @network_keys;
    }
    my ($count, $total) = (0, scalar @network_keys);
    for my $type (@network_keys) {
        $count++;
        my %loop_vars = (
            __first__   => $count == 1,
            __last__    => $count == $total,
            __odd__     => $count % 2,
            __even__    => !($count % 2),
            __counter__ => $count,
        );
        local @$vars{keys %loop_vars} = values %loop_vars;

        my $ndata = $networks->{$type};
        local @$vars{ keys %$ndata } = values %$ndata;
        local $vars->{ident_hint} =
          MT->component('ActionStreams')->translate( $ndata->{ident_hint} )
          if $ndata->{ident_hint};
        local $vars->{label} = $ndata->{name};
        local $vars->{type}  = $type;
        local $vars->{icon_url} =
          ActionStreams::Plugin->icon_url_for_service( $type,
            $networks->{$type} );
        local $ctx->{__stash}{profile_service} = $ndata;
        $out .= $builder->build( $ctx, $tokens, $cond );
    }
    return $out;
}

1;

