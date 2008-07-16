package ActionStreams::Event::TwitterFavorite;

use strict;
use base qw( ActionStreams::Event::Twitter );

__PACKAGE__->install_properties({
    class_type => 'twitter_favorites',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        tweet_author
    ) ],
});

sub as_html {
    my $event = shift;
    my $stream = $event->registry_entry or return '';
    return MT->translate($stream->{html_form} || '',
        MT::Util::encode_html($event->author->nickname),
        MT::Util::encode_html( $event->url ),
        MT::Util::encode_html( $event->tweet_author ),
        $event->autolink( MT::Util::encode_html( $event->title ) ) );
}

1;

