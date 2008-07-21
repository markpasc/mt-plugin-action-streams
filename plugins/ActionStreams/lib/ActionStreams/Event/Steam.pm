
package ActionStreams::Event::Steam;

use strict;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

__PACKAGE__->install_properties({
    class_type => 'steam_achievements',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        gamecode
        ident
        description
    ) ],
});

my %game_for_code = (
    Portal    => 'Portal',
    TF2       => 'Team Fortress 2',
    'HL2:EP2' => 'Half-Life 2: Episode Two',
    'DOD:S'   => 'Day of Defeat: Source',
);

sub as_html {
    my $event = shift;
    return MT->translate('[_1] won the <strong>[_2]</strong> achievement in <a href="http://steamcommunity.com/id/[_3]/stats/[_4]?tab=achievements">[_5]</a>',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( title ident gamecode game ));
}

sub game {
    my $event = shift;
    $game_for_code{$event->gamecode} || $event->gamecode;
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $scraper = scraper {
        process q{//div[@class='achievementClosed']},
            'achvs[]' => scraper {
                process 'h3', 'title' => 'TEXT';
                process 'h5', 'description' => 'TEXT';
            };
        result 'achvs';
    };

    for my $gamecode (keys %game_for_code) {
        my $url = "http://steamcommunity.com/id/$ident/stats/$gamecode?tab=achievements";
        my $items = $class->fetch_scraper(
            url     => $url,
            scraper => $scraper,
        );
        next if !$items;

        for my $item (@$items) {
            $item->{ident}    = $ident;
            $item->{gamecode} = $gamecode;
            $item->{url}      = $url;
        }

        $class->build_results(
            author     => $author,
            items      => $items,
            identifier => 'ident,gamecode,title',
        );
    }

    1;
}


1;

