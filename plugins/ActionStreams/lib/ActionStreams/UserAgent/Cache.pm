
package ActionStreams::UserAgent::Cache;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        id            => 'integer not null auto_increment',
        url           => 'string(255) not null',
        etag          => 'string(255)',
        last_modified => 'string(255)',
        action_type   => 'string(255) not null',
    },
    indexes => {
        url         => 1,
        action_type => 1,
    },
    primary_key => 'id',
    datasource  => 'as_ua_cache',
});

1;
