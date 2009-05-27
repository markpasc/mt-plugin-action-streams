
package ActionStreams::Event::GoogleNews;

use strict;
use base qw( ActionStreams::Event );
use MT::Util qw( remove_html );

__PACKAGE__->install_properties({
        class_type => 'gnews_stories',
});

sub build_results {
    my $self = shift;
    my %params = @_;
    my $items = $params{items};
    for my $item ( @$items ) {
        $item->{title} = remove_html($item->{title});
    }
    $self->SUPER::build_results( @_ );
}

1;
