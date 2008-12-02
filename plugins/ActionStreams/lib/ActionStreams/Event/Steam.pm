
package ActionStreams::Event::Steam;

use strict;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

__PACKAGE__->install_properties({
    class_type => 'steam_achievements',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        gametitle
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

sub game {
    my $event = shift;
    return $event->gametitle || $game_for_code{$event->gamecode}
        || $event->gamecode;
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $achv_scraper = scraper {
        process q{div#BG_top h2},
            'title' => 'TEXT';
        process q{//div[@class='achievementClosed']},
            'achvs[]' => scraper {
                process 'h3',  'title'       => 'TEXT';
                process 'h5',  'description' => 'TEXT';
                process 'img', 'thumbnail'   => '@src';
            };
    };

    my $games = $class->fetch_scraper(
        url => "http://steamcommunity.com/id/$ident/games",
        scraper => scraper {
            process q{div#mainContents a.linkStandard},
                'urls[]' => '@href';
            result 'urls';
        },
    );
    return if !$games;

    for my $url (@$games) {
        my $gamecode = "$url";
        $gamecode =~ s{ \A .* / }{}xms;

        $url = "$url?tab=achievements";  # TF2's stats page has tabs
        my $items = $class->fetch_scraper(
            url     => $url,
            scraper => $achv_scraper,
        );
        next if !$items;

        my ($title, $achvs) = @$items{qw( title achvs )};
        $title =~ s{ \s* Stats \z }{}xmsi;

        for my $item (@$achvs) {
            $item->{gametitle} = $title;
            $item->{ident}     = $ident;
            $item->{gamecode}  = $gamecode;
            $item->{url}       = $url;
            # Stringify thumbnail url as our complicated structure
            # prevents fetch_scraper() from stringifying it for us.
            $item->{thumbnail} = q{} . $item->{thumbnail};
        }

        $class->build_results(
            author     => $author,
            items      => $achvs,
            identifier => 'ident,gamecode,title',
        );
    }

    1;
}


1;

