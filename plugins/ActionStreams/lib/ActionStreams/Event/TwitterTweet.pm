package ActionStreams::Event::TwitterTweet;

use strict;
use base qw( ActionStreams::Event ActionStreams::Event::Twitter );

__PACKAGE__->install_properties({
    class_type => 'twitter_tweets',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        tweet
    ) ],
});

sub as_html {
    my $event = shift;
    my $stream = $event->registry_entry or return '';
    return MT->translate($stream->{html_form} || '',
        MT::Util::encode_html($event->author->nickname),
        MT::Util::encode_html( $event->url ),
        $event->autolink( MT::Util::encode_html( $event->tweet ) ) );
}

1;

