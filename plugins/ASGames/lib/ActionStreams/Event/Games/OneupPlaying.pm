
package ActionStreams::Event::Games::OneupPlaying;

use strict;
use base qw( ActionStreams::Event );

__PACKAGE__->install_properties({
    class_type => 'oneup_playing',
});

__PACKAGE__->install_meta({
    columns => [ qw(
    ) ],
});

sub as_html {
    my $event = shift;
    return MT->translate('[_1] started playing <a href="[_2]">[_3]</a>',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( url title ));
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $url = "http://$ident.1up.com/";

    {
        my $ua = $class->ua();
        local $ua->{max_redirect} = 0;

        my $resp = $ua->get($url);
        return if $resp->code != 304;
        my $real_profile = $resp->header('Location');

        $real_profile =~ m{ \D (\d+) \z }xms or return;
        my $user_id = $1;

        $url = "http://www.1up.com/do/gamesCollectionViewOnly?publicUserId=$user_id";
    }

    my $items = $class->fetch_scraper(
        url     => $url,
        scraper => scraper {
            process 'table#game tbody tr', 'games[]' => scraper {
                process 'a',
                    'url'   => '@href',
                    'title' => 'TEXT';
                process q{td[@class='bodybold'] img[contains(@src, 'icon_check')]},
                    'playing' => '@src';
            };
            result 'games';
        },
    );
    return if !$items;

    for my $item (@$items) {
        $item->{playing} = 1 if $item->{playing};

        $item->{identifier} = join q{:}, $item->{url}, $item->{playing};
    }

    $class->build_results( author => $author, items => $items );
}

1;
