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

1;

