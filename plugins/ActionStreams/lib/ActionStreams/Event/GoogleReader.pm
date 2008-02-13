
package ActionStreams::Event::GoogleReader;

use strict;
use base qw( ActionStreams::Event );

__PACKAGE__->install_properties({
    class_type => 'googlereader_shared',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        summary
        source_title
        source_url
    ) ],
});

sub as_html {
    my $event = shift;
    return MT->translate('[_1] shared <a href="[_2]">[_3]</a> from <a href="[_4]">[_5]</a>',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( url title source_url source_title ));
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $items = $class->fetch_xpath(
        url => "http://www.google.com/reader/public/atom/user/$ident/state/com.google/broadcast",
        foreach => '//entry',
        get => {
            title        => 'title/child::text()',
            summary      => 'summary/child::text()',
            url          => q(link[@rel='alternate']/@href),
            enclosure    => q(link[@rel='enclosure']/@href),
            source_title => 'source/title/child::text()',
            source_url   => q(source/link[@rel='alternate']/@href),
        },
    );
	return if !$items;

    for my $item (@$items) {
        my $enclosure = delete $item->{enclosure};
        $item->{url} ||= $enclosure;
        $item->{identifier} = $item->{url};
    }

    $class->build_results( author => $author, items => $items );
}

1;
