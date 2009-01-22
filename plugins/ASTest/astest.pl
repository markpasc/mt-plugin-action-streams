
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
        callbacks => {
            'MT::App::CMS::init_request' => sub {
                return if MT->app->mode ne 'dialog_add_profile';
                MT->log('ASTest: return args at init_request time are: ' . MT->app->{return_args});
            },
            'template_param.dialog_add_profile' => sub {
                my ($cb, $mt, $param, $tmpl) = @_;
                MT->log('ASTest: networks param to dialog_add_profile is ' . $param->{networks});
                MT->log('ASTest: return_args at dialog_add_profile time is ' . MT->app->{return_args});

                my $profserv = MT->app->registry('profile_services') || {};
                MT->log('ASTest: profile_services at dialog_add_profile time (' . scalar(keys %$profserv) . ') include: ' . join(q{ }, keys %$profserv));
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
            include_paths => [ @INC ],
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

        user => {
            profiles => $app->user->other_profiles,
        },

    };

    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    my $param = { astest => Data::Dumper::Dumper($c) };
    $app->build_page($plugin->load_tmpl('astest.tmpl'), $param);
}


1;

