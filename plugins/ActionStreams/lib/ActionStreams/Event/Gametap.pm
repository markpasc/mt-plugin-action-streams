
package ActionStreams::Event::Gametap;

use strict;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

__PACKAGE__->install_properties({
    class_type => 'gametap_scores',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        score
    ) ],
});

sub as_html {
    my $event = shift;
    return MT->translate('[_1] scored <strong>[_2]</strong> in <a href="[_3]">[_4]</a>',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( score url title ));
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $items = $class->fetch_scraper(
        url => "http://www.gametap.com/home/profile/leaderboards?sn=$ident",
        scraper => scraper {
            # TODO: gametap html
            process 'div.buddy-leaderboards div.tr',
                'achvs[]' => scraper {
                    process 'div.name a',      'url'   => '@href';
                    process 'div.name strong', 'title' => 'TEXT';
                    process 'div.name div',    'score' => [ 'TEXT', sub { s{ \D }{}xmsg } ];
                };
            result 'achvs';
        },
    );
	return if !$items;

    $class->build_results(
        author     => $author,
        items      => $items,
        identifier => 'title,score',
    );
}

1;
