
package ActionStreams::Event::Website;

use strict;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

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

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $links = $class->fetch_scraper(
        unconditional => 1,
        url           => $ident,
        scraper       => scraper {
            process 'head link[type="application/atom+xml"]', 'atom[]' => '@href';
            process 'head link[type="application/rss+xml"]',  'rss[]'  => '@href';
            process 'head link[rel~="shortcut"]',             'icon[]' => '@href';
        },
    );
    return if !$links;

    my ($feed_url, $items);
    if (($feed_url) = @{ $links->{atom} || [] }) {
        $items = $class->fetch_xpath(
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
    }
    elsif (($feed_url) = @{ $links->{rss} || [] }) {
        $items = $class->fetch_xpath(
            url => $feed_url,
            foreach => '//item',
            get => {
                identifier   => 'guid/child::text()',
                title        => 'title/child::text()',
                summary      => 'description/child::text()',
                url          => 'link/child::text()',
                source_title => 'ancestor::channel/title/child::text()',
                source_url   => 'ancestor::channel/link/child::text()',
                created_on   => 'pubDate/child::text()',
                modified_on  => 'pubDate/child::text()',
            },
        );
        for my $item (@$items) {
            $item->{identifier} ||= $item->{url} || $item->{title};
        }
        @$items = grep { $_->{identifier} } @$items;
    }
	return if !$items;

    if (my ($icon_url) = @{ $links->{icon} || [] }) {
        $icon_url = q{} . $icon_url;
        $_->{icon_url} = $icon_url for @$items;
    }

    $class->build_results( author => $author, items => $items );
}

1;
