
package ASTest::Plugin;

use strict;
use warnings;
use base qw( MT::Plugin );

my $plugin = __PACKAGE__->new({
    name => 'ASTest',
    id => 'ASTest',
    key => 'ASTest',
    description => 'Reports general information to try to debug Action Streams',
    author_name => 'Mark Paschal',
});
MT->add_plugin($plugin);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        applications => {
            cms => {
                methods => {
                    astest => \&astest,
                },
            },
        },
    });
}

sub astest {
    my $app = shift;

    require Storable;
    local $Storable::forgive_me = 1;
    my $c = {

        perl => {
            version => $],
        },

        registry => Storable::dclone({
            profile_services => $app->registry('profile_services'),
            action_streams   => $app->registry('action_streams'),
        }),

        mt => {
            version => $MT::VERSION,
            schema  => $MT::SCHEMA_VERSION,
            plugins => Storable::dclone( \%MT::Plugins ),
        },

    };

    require Data::Dumper;
    my $param = { astest => Data::Dumper::Dumper($c) };
    $app->build_page($plugin->load_tmpl('astest.tmpl'), $param);
}


1;

