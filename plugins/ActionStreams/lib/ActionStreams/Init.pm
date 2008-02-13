
package ActionStreams::Init;

use strict;

use MT::Author;

# Say hey, but we really just wanted the module loaded.
sub init_app { 1 }

MT::Author->install_meta({
    columns => [
        'other_profiles',
    ],
});

sub MT::Author::other_profiles {
    my $user = shift;
    my( $type ) = @_;
    my $profiles = $user->meta( 'other_profiles' );
    require Storable;
    $profiles = Storable::thaw($profiles) if !ref $profiles;
    $profiles ||= [];
    return $type ?
        [ grep { $_->{type} eq $type } @$profiles ] :
        $profiles;
}

sub MT::Author::add_profile {
    my $user = shift;
    my( $profile ) = @_;
    my $profiles = $user->other_profiles;
    push @$profiles, $profile;
    $user->meta( other_profiles => $profiles );
    $user->save;
}

sub MT::Author::remove_profile {
    my $user = shift;
    my( $type, $ident ) = @_;
    my $profiles = [ grep {
        $_->{type} ne $type || $_->{ident} ne $ident
    } @{ $user->other_profiles } ];
    $user->meta( other_profiles => $profiles );
    $user->save;
}

1;

