
package ActionStreams::Event::Identica;

use strict;
use base qw( ActionStreams::Event ActionStreams::Event::Twitter );

use MT::Util qw( encode_url );

__PACKAGE__->install_properties({
    class_type => 'identica_statuses',
});

sub search_link_for_tag {
    my $self = shift;
    my ($tag) = @_;
    my $enc_tag = encode_url($tag);
    return qq{<a href="http://identi.ca/tag/$enc_tag">$tag</a>};
}

sub encode_field_for_html {
    return shift->encode_and_autolink_title_field(@_);
}

1;
