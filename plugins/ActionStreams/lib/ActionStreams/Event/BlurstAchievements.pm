package ActionStreams::Event::BlurstAchievements;
use strict;
use warnings;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

__PACKAGE__->install_properties({
    class_type => 'blurst_achievements',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        game_url
        game_title
        description
    ) ],
});

sub _item_id_to_event_data {
    my $class = shift;
    my ($item_id, $ua) = @_;

    my $resp = $ua->post("http://blurst.com/ajax/achievement-tooltip.php",
        { id => $item_id });
    return if !$resp->is_success();

    my $scraper = scraper {
        process 'img', thumbnail => '@src';
        process '.tt-achievement-name', title => 'TEXT';
        process '.tt-achievement-desc', description => 'TEXT';
        process '.tt-achievement-time a',
            game_url => '@href',
            game_title => 'TEXT';
    };
    # Web::Scraper will scrape an HTTP::Response, so use it as the "URL."
    my $event = $scraper->scrape($resp);
    return if !$event;

    $event->{identifier} = $item_id;
    $event->{url} = URI->new_abs($event->{url}, 'http://blurst.com/')->as_string();
    $event->{game_url} = URI->new_abs($event->{game_url}, 'http://blurst.com/')->as_string();
    $event->{game_title} =~ s{ \A \s* Play \s* }{}xms;
    $event->{title} =~ s{ \( .* \z }{}xms;

    return $event;
}

sub update_events {
    my $class = shift;
    my %profile = @_;

    my $author_id = $profile{author}->id;
    my $ident = $profile{ident};

    # Find the IDs of the profile achievements.
    my $items = $class->fetch_scraper(
        url => "http://blurst.com/community/p/$ident",
        scraper => scraper {
            process 'img.achievementicon',
                'id[]' => '@alt';
        },
    );
    return if !$items;
    $items = $items->{id};
    return if !$items || !@$items;

    # Toss all the IDs for which there are already events.
    my %item_ids = map { $_ => 1 } @$items;
    my @events = $class->load({
        author_id => $author_id,
        identifier => [ keys %item_ids ],
    });
    for my $event (@events) {
        delete $item_ids{ $event->identifier };
    }

    # Make events for the remaining achievement IDs.
    my $ua = $class->ua();
    my @event_data = grep { $_ }
        map { $class->_item_id_to_event_data($_, $ua) }
        keys %item_ids;

    return $class->build_results(
        author => $profile{author},
        items => \@event_data,
        profile => \%profile,
    );
}

1;
