package ActionStreams::Plugin;

use strict;

use Carp qw( croak );
use MT::Util qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts );


sub users_content_nav {
    my ($cb, $app, $html_ref) = @_;

    $$html_ref =~ s{class=["']active["']}{}xmsg
        if $app->mode eq 'list_profileevent' || $app->mode eq 'other_profiles';

    $$html_ref =~ m{ "> ((?:<b>)?) <__trans \s phrase="Permissions"> ((?:</b>)?) </a> }xms;
    my ($open_bold, $close_bold) = ($1, $2);

    my $html = <<"EOF";
    <mt:if var="USER_VIEW">
        <li><a href="<mt:var name="SCRIPT_URL">?__mode=other_profiles&amp;id=<mt:var name="EDIT_AUTHOR_ID">">$open_bold<__trans phrase="Other Profiles">$close_bold</a></li>
        <li><a href="<mt:var name="SCRIPT_URL">?__mode=list_profileevent&amp;id=<mt:var name="EDIT_AUTHOR_ID">">$open_bold<__trans phrase="Action Stream">$close_bold</a></li>
    </mt:if>
    <mt:if var="edit_author">
        <li<mt:if name="other_profiles"> class="active"</mt:if>><a href="<mt:var name="SCRIPT_URL">?__mode=other_profiles&amp;id=<mt:var name="id">">$open_bold<__trans phrase="Other Profiles">$close_bold</a></li>
        <li<mt:if name="list_profileevent"> class="active"</mt:if>><a href="<mt:var name="SCRIPT_URL">?__mode=list_profileevent&amp;id=<mt:var name="id">">$open_bold<__trans phrase="Action Stream">$close_bold</a></li>
    </mt:if>
EOF

    $$html_ref =~ s{(?=</ul>)}{$html}xmsg;
}

sub icon_url_for_service {
    my $class = shift;
    my ($type, $ndata) = @_;

    my $plug = $ndata->{plugin} or return;

    my $icon_url;

    if ($plug->id eq 'actionstreams') {
        $icon_url = MT->app->static_path . join q{/}, $plug->envelope,
            'images', 'services', $type . '.png';
    }
    elsif ($ndata->{icon} && $ndata->{icon} =~ m{ \A \w:// }xms) {
        $icon_url = $ndata->{icon};
    }
    elsif ($ndata->{icon}) {
        $icon_url = MT->app->static_path . join q{/}, $plug->envelope,
            $ndata->{icon};
    }

    return $icon_url;
}

sub list_profileevent {
    my $app = shift;
    my %param = @_;

    $app->return_to_dashboard( redirect => 1 ) if $app->param('blog_id');

    my $author_id = $app->param('id')
        or return;
    return $app->error('Not permitted to view')
        if $app->user->id != $author_id && !$app->user->is_superuser();

    my %service_styles;
    my @service_styles_loop;

    my $code = sub {
        my ($event, $row) = @_;

        my @meta_col = keys %{ $event->properties->{meta_columns} || {} };
        $row->{$_} = $event->{$_} for @meta_col;

        $row->{as_html} = $event->as_html();

        my ($service, $stream_id) = split /_/, $row->{class}, 2;
        $row->{type} = $service;

        my $nets = $app->registry('profile_services') || {};
        my $net = $nets->{$service};
        $row->{service} = $net->{name} if $net;

        $row->{url} = $event->url;

        if (!$service_styles{$service}) {
            if (!$net->{plugin} || $net->{plugin}->id ne 'actionstreams') {
                if (my $icon = __PACKAGE__->icon_url_for_service($service, $net)) {
                    push @service_styles_loop, {
                        service_type => $service,
                        service_icon => $icon,
                    };
                }
            }
            $service_styles{$service} = 1;
        }

        my $ts = $row->{created_on};
        $row->{created_on_relative} = relative_date($ts, time);
        $row->{created_on_formatted} = format_ts(
            MT::App::CMS->LISTING_DATETIME_FORMAT(),
            epoch2ts(undef, offset_time(ts2epoch(undef, $ts))),
            undef,
            $app->user ? $app->user->preferred_language : undef,
        );
    };

    # Make sure all classes are loaded.
    require ActionStreams::Event;
    for my $prevt (keys %{ $app->registry('action_streams') }) {
        ActionStreams::Event->classes_for_type($prevt);
    }

    my $plugin = MT->component('ActionStreams');
    my %params = map { $_ => $app->param($_) ? 1 : 0 }
        qw( saved_deleted hidden shown );

    $params{services} = [];
    my $services = $app->registry('profile_services');
    while (my ($prevt, $service) = each %$services) {
        push @{ $params{services} }, {
            service_id   => $prevt,
            service_name => $service->{name},
        };
    }
    $params{services} = [ sort { lc $a->{service_name} cmp lc $b->{service_name} } @{ $params{services} } ];

    my %terms = (
        class => '*',
        author_id => $author_id,
    );
    my %args = (
        sort => 'created_on',
        direction => 'descend',
    );

    if (my $filter = $app->param('filter')) {
        $params{filter_key} = $filter;
        my $filter_val = $params{filter_val} = $app->param('filter_val');
        if ($filter eq 'service') {
            $params{filter_label} = $app->translate('Actions from the service [_1]', $app->registry('profile_services')->{$filter_val}->{name});
            $terms{class} = $filter_val . '_%';
            $args{like} = { class => 1 };
        }
        elsif ($filter eq 'visible') {
            $params{filter_label} = ($filter_val eq 'show') ? 'Actions that are shown'
                : 'Actions that are hidden';
            $terms{visible} = $filter_val eq 'show' ? 1 : 0;
        }
    }

    $params{id} = $params{edit_author_id} = $author_id;
    $params{service_styles} = \@service_styles_loop;
    $app->listing({
        type     => 'profileevent',
        terms    => \%terms,
        args     => \%args,
        listing_screen => 1,
        code     => $code,
        template => $plugin->load_tmpl('list_profileevent.tmpl'),
        params   => \%params,
    });
}

sub itemset_hide_events {
    my ($app) = @_;
    $app->validate_magic or return;

    my @events = $app->param('id');

    for my $event_id (@events) {
        my $event = MT->model('profileevent')->load($event_id)
          or next;
        next if $app->user->id != $event->author_id && !$app->user->is_superuser();
        $event->visible(0);
        $event->save;
    }

    $app->add_return_arg( hidden => 1 );
    $app->call_return;
}

sub itemset_show_events {
    my ($app) = @_;
    $app->validate_magic or return;

    my @events = $app->param('id');

    for my $event_id (@events) {
        my $event = MT->model('profileevent')->load($event_id)
          or next;
        next if $app->user->id != $event->author_id && !$app->user->is_superuser();
        $event->visible(1);
        $event->save;
    }

    $app->add_return_arg( shown => 1 );
    $app->call_return;
}

sub _itemset_hide_show_all_events {
    my ($app, $new_visible) = @_;
    $app->validate_magic or return;
    my $event_class = MT->model('profileevent');

    # Really we should work directly from the selected author ID, but as an
    # itemset event we only got some event IDs. So use its.
    my ($event_id) = $app->param('id');
    my $event = $event_class->load($event_id)
        or return $app->error($app->translate('No such event [_1]', $event_id));

    my $author_id = $event->author_id;
    return $app->error('Not permitted to modify')
        if $author_id != $app->user->id && !$app->is_superuser();

    my $driver = $event_class->driver;
    my $stmt = $driver->prepare_statement($event_class, {
        # TODO: include filter value when we have filters
        author_id => $author_id,
        visible   => $new_visible ? 0 : 1,
    });

    my $sql = "UPDATE " . $driver->table_for($event_class) . " SET "
        . $driver->dbd->db_column_name($event_class->datasource, 'visible')
        . " = ? " . $stmt->as_sql_where;

    # Work around error in MT::ObjectDriver::Driver::DBI::sql by doing it inline.
    my $dbh = $driver->rw_handle;
    $dbh->do($sql, {}, $new_visible, @{ $stmt->{bind} })
        or return $app->error($dbh->errstr);

    return 1;
}

sub itemset_hide_all_events {
    my $app = shift;
    _itemset_hide_show_all_events($app, 0) or return;
    $app->add_return_arg( all_hidden => 1 );
    $app->call_return;
}

sub itemset_show_all_events {
    my $app = shift;
    _itemset_hide_show_all_events($app, 1) or return;
    $app->add_return_arg( all_shown => 1 );
    $app->call_return;
}

sub _build_service_data {
    my %info = @_;
    my ($networks, $streams, $author) = @info{qw( networks streams author )};
    my (@service_styles_loop, @networks);

    my %has_profiles;
    if ($author) {
        my $other_profiles = $author->other_profiles();
        $has_profiles{$_->{type}} = 1 for @$other_profiles;
    }

    my @network_keys = sort { lc $networks->{$a}->{name} cmp lc $networks->{$b}->{name} }
        keys %$networks;
    TYPE: for my $type (@network_keys) {
        my $ndata = $networks->{$type}
            or next TYPE;

        my @streams;
        if ($streams) {
            my $streamdata = $streams->{$type} || {};
            @streams =
                sort { lc $a->{name} cmp lc $b->{name} }
                grep { grep { $_ } @$_{qw( class scraper xpath rss atom )} }
                map  { +{ stream => $_, %{ $streamdata->{$_} } } }
                grep { $_ ne 'plugin' }
                keys %$streamdata;
        }

        my $ret = {
            type => $type,
            %$ndata,
            label => $ndata->{name},
            user_has_account => ($has_profiles{$type} ? 1 : 0),
        };
        $ret->{streams} = \@streams if @streams;
        push @networks, $ret;

        if (!$ndata->{plugin} || $ndata->{plugin}->id ne 'actionstreams') {
            push @service_styles_loop, {
                service_type => $type,
                service_icon => __PACKAGE__->icon_url_for_service($type, $ndata),
            };
        }
    }

    return (
        service_styles => \@service_styles_loop,
        networks       => \@networks,
    );
}

sub upgrade_enable_existing_streams {
    my ($author) = @_;
    my $app = MT->app;

    my $profiles = $author->other_profiles();
    return if !$profiles || !@$profiles;

    for my $profile (@$profiles) {
        my $type = $profile->{type};
        my $streams = $app->registry('action_streams', $type);
        $profile->{streams} = { map { join(q{_}, $type, $_) => 1 } keys %$streams };
    }

    $author->meta( other_profiles => $profiles );
    $author->save;
}

sub upgrade_reclass_actions {
    my ($upg, %param) = @_;

    my $action_class = MT->model('profileevent');
    my $driver = $action_class->driver;
    my $dbd = $driver->dbd;
    my $dbh = $driver->rw_handle;
    my $class_col = $dbd->db_column_name($action_class->datasource, 'class');

    my %reclasses = (
        'twitter_tweets' => 'twitter_statuses',
        'pownce_notes'   => 'pownce_statuses',
    );

    my $app      = MT->instance;
    my $plugin   = MT->component('ActionStreams');
    my $services = $app->registry('profile_services');
    my $streams  = $app->registry('action_streams');
    while (my ($old_class, $new_class) = each %reclasses) {
        my ($service, $stream) = split /_/, $new_class, 2;
        $upg->progress($plugin->translate('Updating classification of [_1] [_2] actions...',
            $services->{$service}->{name}, $streams->{$service}->{$stream}->{name}));

        my $stmt = $dbd->sql_class->new;
        $stmt->add_where( $class_col => $old_class );
        my $sql = join q{ }, 'UPDATE', $driver->table_for($action_class),
            'SET', $class_col, '= ?', $stmt->as_sql_where();
        $dbh->do($sql, {}, $new_class, @{ $stmt->{bind} })
            or die $dbh->errstr;
    }

    return 0;  # done
}

sub other_profiles {
    my( $app ) = @_;

    $app->return_to_dashboard( redirect => 1 ) if $app->param('blog_id');

    my $author_id = $app->param('id')
        or return $app->error('Author id is required');
    my $user = MT->model('author')->load($author_id)
        or return $app->error('Author id is invalid');
    return $app->error('Not permitted to view')
        if $app->user->id != $author_id && !$app->user->is_superuser();

    my $plugin = MT->component('ActionStreams');
    my $tmpl = $plugin->load_tmpl( 'other_profiles.tmpl' );

    my @profiles = sort { lc $a->{label} cmp lc $b->{label} }
        @{ $user->other_profiles || [] };

    my %messages = map { $_ => $app->param($_) ? 1 : 0 }
        (qw( added removed updated edited ));
    return $app->build_page( $tmpl, {
        id             => $user->id,
        edit_author_id => $user->id,
        profiles       => \@profiles,
        listing_screen => 1,
        _build_service_data(
            networks => $app->registry('profile_services'),
        ),
        %messages,
    } );
}

sub dialog_add_edit_profile {
    my ($app) = @_;

    return $app->error('Not permitted to view')
        if $app->user->id != $app->param('author_id') && !$app->user->is_superuser();
    my $author = MT->model('author')->load($app->param('author_id'))
        or return $app->error('No such author [_1]', $app->param('author_id'));

    my %edit_profile;
    my $tmpl_name = 'dialog_add_profile.tmpl';
    if (my $edit_type = $app->param('profile_type')) {
        my $ident = $app->param('profile_ident') || q{};
        my ($profile) = grep { $_->{ident} eq $ident }
            @{ $author->other_profiles($edit_type) };

        %edit_profile = (
            edit_type      => $edit_type,
            edit_type_name => $app->registry('profile_services', $edit_type, 'name'),
            edit_ident     => $ident,
            edit_streams   => $profile->{streams} || [],
        );

        $tmpl_name = 'dialog_edit_profile.tmpl';
    }

    my $plugin = MT->component('ActionStreams');
    my $tmpl = $plugin->load_tmpl($tmpl_name);

    return $app->build_page($tmpl, {
        edit_author_id => $app->param('author_id'),
        _build_service_data(
            networks => $app->registry('profile_services'),
            streams  => $app->registry('action_streams'),
            author   => $author,
        ),
        %edit_profile,
    });
}

sub edit_other_profile {
    my $app = shift;
    $app->validate_magic() or return;

    my $author_id = $app->param('author_id')
        or return $app->error('Author id is required');
    my $user = MT->model('author')->load($author_id)
        or return $app->error('Author id is invalid');
    return $app->error('Not permitted to edit')
        if $app->user->id != $author_id && !$app->user->is_superuser();

    my $type = $app->param('profile_type');
    my $orig_ident = $app->param('original_ident');

    $user->remove_profile($type, $orig_ident);

    $app->forward('add_other_profile', success_msg => 'edited');
}

sub add_other_profile {
    my $app = shift;
    my %param = @_;
    $app->validate_magic or return;

    my $author_id = $app->param('author_id')
        or return $app->error('Author id is required');
    my $user = MT->model('author')->load($author_id)
        or return $app->error('Author id is invalid');
    return $app->error('Not permitted to add')
        if $app->user->id != $author_id && !$app->user->is_superuser();

    my( $ident, $uri, $label, $type );
    if ( $type = $app->param( 'profile_type' ) ) {
        my $reg = $app->registry('profile_services');
        my $network = $reg->{$type}
            or croak "Unknown network $type";
        $label = $network->{name} . ' Profile';

        $ident = $app->param( 'profile_id' );
        $ident =~ s{ \A \s* }{}xms;
        $ident =~ s{ \s* \z }{}xms;

        # Check for full URLs.
        if (!$network->{ident_exact}) {
            my $url_pattern = $network->{url};
            my ($pre_ident, $post_ident) = split /(?:\%s|\Q{{ident}}\E)/, $url_pattern, 2;
            $pre_ident =~ s{ \A http:// }{}xms;
            $post_ident =~ s{ / \z }{}xms;
            if ($ident =~ m{ \A (?:http://)? \Q$pre_ident\E (.*?) \Q$post_ident\E /? \z }xms) {
                $ident = $1;
            }
        }

        $uri = $network->{url};
        $uri =~ s{ (?:\%s|\Q{{ident}}\E) }{$ident}xmsg;
    } else {
        $ident = $uri = $app->param( 'profile_uri' );
        $label = $app->param( 'profile_label' );
        $type = 'website';
    }

    my $profile = {
        type    => $type,
        ident   => $ident,
        label   => $label,
        uri     => $uri,
    };

    my %streams = map { join(q{_}, $type, $_) => 1 }
        grep { $_ ne 'plugin' && $app->param(join q{_}, 'stream', $type, $_) }
        keys %{ $app->registry('action_streams', $type) || {} };
    $profile->{streams} = \%streams if %streams;

    $app->run_callbacks('pre_add_profile.'  . $type, $app, $user, $profile);
    $user->add_profile($profile);
    $app->run_callbacks('post_add_profile.' . $type, $app, $user, $profile);

    my $success_msg = $param{success_msg} || 'added';
    return $app->redirect($app->uri(
        mode => 'other_profiles',
        args => { id => $author_id, $success_msg => 1 },
    ));
}

sub remove_other_profile {
    my( $app ) = @_;
    $app->validate_magic or return;

    my %users;
    my $page_author_id;
    PROFILE: for my $profile ($app->param('id')) {
        my ($author_id, $type, $ident) = split /:/, $profile, 3;

        my $user = ($users{$author_id} ||= MT->model('author')->load($author_id))
            or next PROFILE;
        next PROFILE
            if $app->user->id != $author_id && !$app->user->is_superuser();

        $app->run_callbacks('pre_remove_profile.'  . $type, $app, $user, $type, $ident);
        $user->remove_profile( $type, $ident );
        $app->run_callbacks('post_remove_profile.' . $type, $app, $user, $type, $ident);
        $page_author_id = $author_id;
    }

    return $app->redirect($app->uri(
        mode => 'other_profiles',
        args => { id => ($page_author_id || $app->user->id), removed => 1 },
    ));
}

sub itemset_update_profiles {
    my $app = shift;

    my %users;
    my $page_author_id;
    PROFILE: for my $profile ($app->param('id')) {
        my ($author_id, $type, $ident) = split /:/, $profile, 3;

        my $user = ($users{$author_id} ||= MT->model('author')->load($author_id))
            or next PROFILE;
        next PROFILE
            if $app->user->id != $author_id && !$app->user->is_superuser();

        my $profiles = $user->other_profiles($type);
        if (!$profiles) {
            next PROFILE;
        }
        my @profiles = grep { $_->{ident} eq $ident } @$profiles;
        for my $author_profile (@profiles) {
            update_events_for_profile($user, $author_profile,
                synchronous => 1);
        }

        $page_author_id = 1;
    }

    return $app->redirect($app->uri(
        mode => 'other_profiles',
        args => { id => ($page_author_id || $app->user->id), updated => 1 },
    ));
}

sub first_profile_update {
    my ($cb, $app, $user, $profile) = @_;
    update_events_for_profile($user, $profile,
        synchronous => 1, hide_timeless => 1);
}

sub rebuild_action_stream_blogs {
    my ($cb, $app) = @_;
    return if !$app->request('saved_action_stream_events');

    my $plugin = MT->component('ActionStreams');
    my $pd_iter = MT->model('plugindata')->load_iter({
        plugin => $plugin->key,
        key => { like => 'configuration:blog:%' }
    });
    my %rebuild;
    while ( my $pd = $pd_iter->() ) {
        next unless $pd->data('rebuild_for_action_stream_events');
        my ($blog_id) = $pd->key =~ m/:blog:(\d+)$/;
        $rebuild{$blog_id} = 1;
    }
    foreach my $blog_id (keys %rebuild) {
        # FIXME: We could possibly limit this further so we only rebuild
        # indexes that use actionstreams...
        my $blog = MT->model('blog')->load( $blog_id ) or next;
        $app->rebuild_indexes( Blog => $blog );
    }
}

sub _twitter_add_tags_to_item {
    my ($item) = @_;
    if (my @tags = $item->{title} =~ m{
        (?: \A | \s )  # BOT or whitespace
        \#             # hash
        (\w\S*\w)      # tag
        (?<! 's )      # but don't end with 's
    }xmsg) {
        $item->{tags} = \@tags;
    }
}

sub fix_twitter_tweet_name {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the Twitter username from the front of the tweet.
    my $ident = $profile->{ident};
    $item->{title} =~ s{ \A \s* \Q$ident\E : \s* }{}xmsi;
    _twitter_add_tags_to_item($item);
}

sub fix_twitter_favorite_author {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the Twitter username from the front of the tweet.
    if ($item->{title} =~ s{ \A \s* ([^\s:]+) : \s* }{}xms) {
        $item->{tweet_author} = $1;
    }
    _twitter_add_tags_to_item($item);
}

sub fix_flickr_photo_thumbnail {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Extract just the URL, and use the _t size thumbnail, not the _m size image.
    my $thumb = delete $item->{thumbnail};
    if ($thumb =~ m{ (http://farm[^\.]+\.static\.flickr\.com .*? _m.jpg) }xms) {
        $thumb = $1;
        $thumb =~ s{ _m.jpg \z }{_t.jpg}xms;
        $item->{thumbnail} = $thumb;
    }
}

sub fix_iminta_link_title {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the username for when we add it back in later.
    $item->{title} =~ s{ (?: \s* :: [^:]+ ){2} \z }{}xms;
}

sub fix_iusethis_event_title {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the username for when we add it back in later.
    $item->{title} =~ s{ \A \w+ \s* }{}xms;
}

sub fix_netflix_recent_prefix_thumb {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the 'Shipped:' or 'Received:' prefix.
    $item->{title} =~ s{ \A [^:]*: \s* }{}xms;

    # Extract thumbnail from description.
    my $thumb = delete $item->{thumbnail};
    if ($thumb =~ m/ <img src="([^"]+)"} /xms) {
        $item->{thumbnail} = $1;
    }
}

sub fix_netflix_queue_prefix_thumb {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the item number.
    $item->{title} =~ s{ \A \d+ [\W\S] \s* }{}xms;

    # Extract thumbnail from description.
    my $thumb = delete $item->{thumbnail};
    if ($thumb =~ m/ <img src="([^"]+)"} /xms) {
        $item->{thumbnail} = $1;
    }
}

sub fix_p0pulist_stuff_urls {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    $item->{url} =~ s{ \A / }{http://p0pulist.com/}xms;
}

sub fix_kongregate_achievement_title_thumb {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Remove the parenthetical from the end of the title.
    $item->{title} =~ s{ \( [^)]* \) \z }{}xms;

    # Pick the actual achievement badge out of the inline CSS.
    my $thumb = delete $item->{thumbnail};
    if ($thumb =~ m{ background-image: \s* url\( ([^)]+) }xms) {
        $item->{thumbnail} = $1;
    }
}

sub fix_wists_thumb {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    # Grab the wists thumbnail out.
    my $thumb = delete $item->{thumbnail};
    if ($thumb =~ m{ (http://cache.wists.com/thumbnails/ [^"]+ ) }xms) {
        $item->{thumbnail} = $1;
    }
}

sub fix_gametap_score_stuff {
    my ($cb, $app, $item, $event, $author, $profile) = @_;
    $item->{score} =~ s{ \D }{}xmsg;
    $item->{url} = q{} . $item->{url};
    $item->{url} =~ s{ \A / }{http://www.gametap.com/}xms;
}

sub tag_stream_action {
    my ($ctx, $args, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamAction in a non-action-stream context!");
    return $event->as_html($ctx);
}

sub tag_stream_action_var {
    my ($ctx, $arg, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionVar in a non-action-stream context!");
    my $var = $arg->{var} || $arg->{name}
        or return $ctx->error("Used StreamActionVar without a 'name' attribute!");
    return $ctx->error("Use StreamActionVar to retrieve invalid variable $var from event of type " . ref $event)
        if !$event->can($var) && !$event->has_column($var);
    return $event->$var();
}

sub tag_stream_action_date {
    my ($ctx, $arg, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionDate in a non-action-stream context!");
    my $c_on = $event->created_on;
    local $arg->{ts} = epoch2ts( $ctx->stash('blog'), ts2epoch(undef, $c_on) )
        if $c_on;
    return $ctx->_hdlr_date($arg);
}

sub tag_stream_action_modified_date {
    my ($ctx, $arg, $cond) = @_;

    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionModifiedDate in a non-action-stream context!");
    my $m_on = $event->modified_on || $event->created_on;
    local $arg->{ts} = epoch2ts( $ctx->stash('blog'), ts2epoch(undef, $m_on) )
        if $m_on;
    return $ctx->_hdlr_date($arg);
}

sub tag_stream_action_title {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionTitle in a non-action-stream context!");
    return $event->title || '';
}

sub tag_stream_action_url {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionURL in a non-action-stream context!");
    return $event->url || '';
}

sub tag_stream_action_thumbnail_url {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionThumbnailURL in a non-action-stream context!");
    return $event->thumbnail || '';
}

sub tag_other_profile_var {
    my( $ctx, $args ) = @_;
    my $profile = $ctx->stash( 'other_profile' )
        or return $ctx->error( 'No profile defined in ProfileVar' );
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
        @author_ids = map { $_->id } @authors;
    }

    return \@author_ids;
}

sub tag_action_streams_block {
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

    if (my $limit = $args->{limit} || $args->{lastn}) {
        $args{limit} = $limit;
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
    next EVENT if !$profile;
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

sub tag_stream_action_rollup {
    my ($ctx, $arg, $cond) = @_;
    my $event = $ctx->stash('stream_action')
        or return $ctx->error("Used StreamActionRollup in a non-action-stream context!");
    my $nexts = $ctx->stash('remaining_stream_actions');
    return $ctx->_hdlr_pass_tokens_else($arg, $cond)
        if !$nexts || !@$nexts || $event->class ne $nexts->[0]->class;
    $nexts ||= [];

    my $event_class = $event->class;
    my $event_date  = _event_day($ctx, $event);

    my @rollup_events = ($event);
    while (@$nexts && $nexts->[0]->class eq $event_class && $event_date eq _event_day($ctx, $nexts->[0])) {
        push @rollup_events, shift @$nexts;
    }

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

sub tag_stream_action_tags {
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

sub tag_other_profiles {
    my( $ctx, $args, $cond ) = @_;

    my $author_ids = _author_ids_for_args(@_);
    my $author_id = shift @$author_ids
        or return $ctx->error('No author specified for OtherProfiles');
    my $user = MT->model('author')->load($author_id)
        or return $ctx->error(MT->trans('No user [_1]', $author_id));

    my @profiles = @{ $user->other_profiles() };
    my $services;
    if (my $filter_type = $args->{type}) {
        my $filter_except = $filter_type =~ s{ \A NOT \s+ }{}xmsi ? 1 : 0;
        @profiles = grep {
            my $profile = $_;
            my $profile_type = $profile->{type};
            $services ||= MT->app->registry('profile_services');
            my $service_type = ($services->{$profile_type} || {})->{service_type} || q{};
            $filter_except ? $service_type ne $filter_type : $service_type eq $filter_type;
        } @profiles;
    }

    return list(
        context    => $ctx,
        arguments  => $args,
        conditions => $cond,
        items      => \@profiles,
        stash_key  => 'other_profile',
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
    my $vars = ($ctx->{__stash}{vars} ||= {});
    my ($count, $total) = (0, scalar @$items);
    for my $item (@$items) {
        local $ctx->{__stash}->{$stash_key} = $item;

        my $row = {};
        $code->($item, $row) if $code;
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

        $res .= $glue if $res && $glue;
        $res .= $out;
    }

    return $res;
}

sub tag_profile_services {
    my( $ctx, $args, $cond ) = @_;

    my $app = MT->app;
    my $networks = $app->registry('profile_services');
    my @network_keys = sort { lc $networks->{$a}->{name} cmp lc $networks->{$b}->{name} }
        keys %$networks;

    my $out = "";
    my $builder = $ctx->stash( 'builder' );
    my $tokens = $ctx->stash( 'tokens' );
    my $vars = $ctx->stash('vars');
    TYPE: for my $type (@network_keys) {
        my $ndata = $networks->{$type};
        # Skip output completely if it's a "core" service but we want
        # extras only.
        next TYPE if $args->{extra} && $ndata->{plugin}
            && $ndata->{plugin}->id eq 'actionstreams';

        local $vars->{type} = $type;
        local $vars->{keys %$ndata} = values %$ndata;
        local $vars->{label} = $ndata->{name};
        local $vars->{icon_url} = __PACKAGE__->icon_url_for_service($type, $networks->{$type});
        $out .= $builder->build( $ctx, $tokens, $cond );
    }
    return $out;
}

sub widget_recent {
    my ($app, $tmpl, $widget_param) = @_;
    $tmpl->param('author_id', $app->user->id);
    $tmpl->param('blog_id', $app->blog->id) if $app->blog;
}

sub widget_blog_dashboard_only {
    my ($page, $scope) = @_;
    return if $scope eq 'dashboard:system';
    return 1;
}

sub update_events {
    my $mt = MT->app;
    $mt->run_callbacks('pre_action_streams_task', $mt);

    my $author_iter = MT::Author->search({ type => MT::Author->AUTHOR() });
    while (my $author = $author_iter->()) {
        my $profiles = $author->other_profiles();
        $mt->run_callbacks('pre_update_action_streams',  $mt, $author, $profiles);

        PROFILE: for my $profile (@$profiles) {
            update_events_for_profile($author, $profile);
        }

        $mt->run_callbacks('post_update_action_streams', $mt, $author, $profiles);
    }

    $mt->run_callbacks('post_action_streams_task', $mt);
}

sub update_events_for_profile {
    my ($author, $profile, %param) = @_;
    my $type = $profile->{type};
    my $streams = $profile->{streams};
    return if !$streams || !%$streams;

    require ActionStreams::Event;
    my @event_classes = ActionStreams::Event->classes_for_type($type)
      or return;

    my $mt = MT->app;
    $mt->run_callbacks('pre_update_action_streams_profile.' . $profile->{type},
        $mt, $author, $profile);
    EVENTCLASS: for my $event_class (@event_classes) {
        next EVENTCLASS if !$streams->{$event_class->class_type};

        if ($param{synchronous}) {
            $event_class->update_events_safely(
                author        => $author,
                hide_timeless => $param{hide_timeless} ? 1 : 0,
                %$profile,
            );
        }
        else {
            # Defer regular updates to job workers.
            require ActionStreams::Worker;
            ActionStreams::Worker->make_work(
                event_class => $event_class,
                author      => $author,
                %$profile,
            );
        }
    }
    $mt->run_callbacks('post_update_action_streams_profile.' . $profile->{type},
        $mt, $author, $profile);
}

1;

