
package ActionStreams::Event::OneupPlaying;

use strict;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

__PACKAGE__->install_properties({
    class_type => 'oneup_playing',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        playing
    ) ],
});

sub as_html {
    my $event = shift;
    my $form = $event->playing ? '[_1] started playing <a href="[_2]">[_3]</a>'
             :                   '[_1] played <a href="[_2]">[_3]</a>'
             ;
    return $event->SUPER::as_html( form => $form );
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $url = "http://$ident.1up.com/";

    {
        my $ua = $class->ua();
        my @redir = @{ $ua->requests_redirectable };
        $ua->requests_redirectable([]);

        my $resp = $ua->get($url);
        $ua->requests_redirectable(\@redir);

        return if $resp->code != 301;
        my $real_profile = $resp->header('Location');

        if ($real_profile !~ m{ \D (\d+) \z }xms) {
            # Hmm, invalid ident?
            return;
        }
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
                process q{td.bodybold img[src=~'icon_check']},
                    'playing' => '@src';
            };
            result 'games';
        },
    );
    return if !$items;

    for my $item (@$items) {
        $item->{playing} = $item->{playing} ? 1 : 0;
        $item->{identifier} = $item->{url};
    }

    $class->build_results( author => $author, items => $items );
}

1;
