
package ActionStreams::UserAgent::Cache;
use base qw( MT::Object );

__PACKAGE__->install_properties({
    column_defs => {
        url           => 'string(255) not null',
        etag          => 'string(255)',
        last_modified => 'string(255)',
    },
    indexes => {
        url => 1,
    },
    primary_key => 'url',
    datasource  => 'actions_ua_cache',
});

1;
