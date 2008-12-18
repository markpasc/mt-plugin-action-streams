package ActionStreams::Upgrade;

use strict;
use warnings;

sub enable_existing_streams {
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

sub reclass_actions {
    my ($upg, %param) = @_;

    my $action_class = MT->model('profileevent');
    my $driver = $action_class->driver;
    my $dbd = $driver->dbd;
    my $dbh = $driver->rw_handle;
    my $class_col = $dbd->db_column_name($action_class->datasource, 'class');

    my $reg_reclasses = MT->component('ActionStreams')->registry(
        'upgrade_data', 'reclass_actions');
    my %reclasses = %$reg_reclasses;
    delete $reclasses{plugin};  # just in case

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

sub rename_action_metadata {
    my ($upg, %param) = @_;

    my $action_class = MT->model('profileevent');
    my $driver       = $action_class->driver;
    my $dbd          = $driver->dbd;
    my $dbh          = $driver->rw_handle;

    my $action_table    = $driver->table_for($action_class);
    my $action_type_col = $dbd->db_column_name($action_class->datasource, 'class');
    my $action_id_col   = $dbd->db_column_name($action_class->datasource, 'id');

    my $meta_class  = $action_class->meta_pkg;
    my $meta_table  = $driver->table_for($meta_class);
    my $type_col    = $dbd->db_column_name($meta_class->datasource, 'type');
    my $meta_id_col = $dbd->db_column_name($meta_class->datasource, 'profileevent_id');

    my $reg_renames = MT->component('ActionStreams')->registry('upgrade_data',
        'rename_action_metadata');
    my @renames = @$reg_renames;

    my $app      = MT->instance;
    my $plugin   = MT->component('ActionStreams');
    my $services = $app->registry('profile_services');
    my $streams  = $app->registry('action_streams');
    for my $rename (@renames) {
        my ($service, $stream) = split /_/, $rename->{action_type}, 2;
        $upg->progress($plugin->translate('Renaming "[_1]" data of [_2] [_3] actions...',
            $rename->{old},
            $services->{$service}->{name}, $streams->{$service}->{$stream}->{name}));

        my $stmt = $dbd->sql_class->new;
        $stmt->add_where( $type_col        => $rename->{old} );
        $stmt->add_where( $action_type_col => $rename->{action_type} );
        $stmt->add_where( $meta_id_col     => \"= $action_id_col");

        my $sql = join q{ }, 'UPDATE', $meta_table, q{,}, $action_table,
            'SET', $type_col, '= ?', $stmt->as_sql_where();
        $dbh->do($sql, {}, $rename->{new}, @{ $stmt->{bind} })
            or die $dbh->errstr;
    }

    return 0;  # done
}

sub rename_action_table {
    my ($upg, %param) = @_;

    my $action_class = MT->model('profileevent');
    my $driver       = $action_class->driver;
    my $ddl_class    = $driver->dbd->ddl_class;
    if (0 && $ddl_class =~ m{ \b mysql \z }xms) {
        $upg->add_step('rename_action_table_mysql');
    }
    else {
        $upg->add_step('rename_action_table_copy');
        $upg->add_step('rename_action_table_meta');
    }

    return 0;  # delegated
}

sub rename_action_table_mysql {
    my ($upg, %param) = @_;

    my $plugin = MT->component('ActionStreams');
    $upg->progress($plugin->translate('Copying action data over to new tables...'));

    my $action_class = MT->model('profileevent');
    my $driver       = $action_class->driver;
    my $ddl_class    = $driver->dbd->ddl_class;
    my $table_name   = $action_class->table_name;

    my $sql = $ddl_class->create_table_as_sql($action_class);
    my $old_table_name = join q{}, $driver->prefix, 'profileevent';
    $sql =~ s{ \b \Q$table_name\E          \b }{$old_table_name}xmsg;
    $sql =~ s{ \b \Q$table_name\E _upgrade \b }{$table_name}xmsg;

    my $dbh = $driver->rw_handle;
    $dbh->do(qq{INSERT IGNORE INTO $table_name SELECT * FROM $old_table_name})
        or die $dbh->errstr;
    $dbh->do(qq{INSERT IGNORE INTO ${table_name}_meta SELECT * FROM ${old_table_name}_meta})
        or die $dbh->errstr;

    return 0;  # done
}

sub rename_action_table_copy {
    my $props = MT->model('profileevent')->properties;
    return _rename_some_action_table(@_,
        info => {
            pkg   => 'ActionStreams::Event',
            base  => 'MT::Object',
            ds    => 'profileevent',
            clone => sub { return (
                column_defs => { %{ $props->{column_defs} } },
                primary_key => $props->{primary_key},
            ) },
            iter  => sub { return shift->load_iter(@_) },
            prog  => 'Copying action data over to new tables ([_1]%)...',
        },
    );
}

sub _clone_property_for_action_meta_table {
    my ($stuff) = @_;
    my @ret = map { $_ eq 'as_id' ? 'profileevent_id' : $_ } @$stuff;
    return \@ret;
}

sub _get_remapped_properties_for_action_meta_table {
    my $meta_props = MT->model('profileevent')->meta_pkg->properties;
    return (
        columns     => _clone_property_for_action_meta_table($meta_props->{columns}),
        primary_key => _clone_property_for_action_meta_table($meta_props->{primary_key}),
    );
}

sub rename_action_table_meta {
    return _rename_some_action_table(@_,
        info => {
            pkg   => 'ActionStreams::Event::Meta',
            base  => 'MT::Object::Meta',
            ds    => 'profileevent_meta',
            clone => \&_get_remapped_properties_for_action_meta_table,
            iter  => sub { return scalar shift->search(@_) },
            prog  => 'Copying more action data over to new tables ([_1]%)...',
            fix   => sub { $_[0]->{as_id} = delete $_[0]->{profileevent_id} },
        },
    );
}

sub _rename_some_action_table {
    my ($upg, %param) = @_;

    my $plugin = MT->component('ActionStreams');
    my $info = delete $param{info}
        or die $plugin->translate('Tried to rename an action table with no table info?');
    my ($pkg, $base, $clone, $datasource, $load_iter, $progress_str, $fixup)
        = @$info{qw( pkg base clone ds iter prog fix )};
    my $clone_pkg = $pkg;
    $pkg = "Old::$pkg";

    # Define our legacy model if it hasn't already been defined.
    if (!eval { $pkg->properties }) {
        eval "package $pkg; use base qw( $base ); 1"
            or die $@;

        my %clone_props = $clone->();
        $pkg->install_properties({
            %clone_props,
            datasource => $datasource,
        });
    }

    my $limit    = 50;
    my $complete = 1000;
    my $offset   = $param{offset} || 0;
    my $count    = $pkg->count();
    if ($count) {
        $complete = int ($offset / $count * 100);
        $complete = 100 if $complete > 100;
    }

    $upg->progress($plugin->translate($progress_str, $complete),
        $param{step});

    # Build a sort parameter that ensures we get a stable search throughout
    # all the runs of this step.
    my @sort = map { +{ column => $_, desc => 'DESC' } }
        @{ $pkg->primary_key_tuple };

    my $iter = $load_iter->($pkg, {}, {
        sort   => \@sort,
        limit  => $limit,
        offset => $offset,
    }) or die $pkg->errstr;

    my $moved_actions;
    while (my $old_action = $iter->()) {
        my $values = $old_action->column_values;
        $fixup->($values) if $fixup;

        my $action = $clone_pkg->new;
        $action->set_values($values);
        $action->save or die $action->errstr;

        $moved_actions = 1;
    }
    $iter->('finish');

    return $moved_actions ? $offset + $limit : 0;
}

1;

