
package ActionStreams::Event::Website;

use strict;
use base qw( ActionStreams::Event );

use Web::Scraper;

__PACKAGE__->install_properties({
    class_type => 'website_posted',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        summary
        source_title
        source_url
        icon_url
    ) ],
});

sub as_html {
    my $event = shift;
    return MT->translate('[_1] posted <a href="[_2]">[_3]</a> on <a href="[_4]">[_5]</a>',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( url title source_url source_title ));
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $links = $class->fetch_scraper(
        url     => $ident,
        scraper => scraper {
            process 'head link[type="application/atom+xml"]', 'atom[]' => '@href';
            process 'head link[rel~="shortcut"]',             'icon[]' => '@href';
        },
    );
    return if !$links;
    my ($feed_url) = @{ $links->{atom} || [] };
    return if !$feed_url;
    my ($icon_url) = @{ $links->{icon} || [] };

    my $items = $class->fetch_xpath(
        url => $feed_url,
        foreach => '//entry',
        get => {
            identifier   => 'id/child::text()',
            title        => 'title/child::text()',
            summary      => 'summary/child::text()',
            url          => q(link[@rel='alternate']/@href),
            source_title => 'ancestor::feed/title/child::text()',
            source_url   => q(ancestor::feed/link[@rel='alternate']/@href),
            created_on   => 'published/child::text()',
            modified_on  => 'updated/child::text()',
        },
    );
	return if !$items;

    if ($icon_url) {
        $icon_url = q{} . $icon_url;
        $_->{icon_url} = $icon_url for @$items;
    }

    $class->build_results( author => $author, items => $items );
}

1;

