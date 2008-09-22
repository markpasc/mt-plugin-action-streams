package ActionStreams::Event::TwitterTweet;

use strict;
use base qw( ActionStreams::Event ActionStreams::Event::Twitter );

__PACKAGE__->install_properties({
    class_type => 'twitter_statuses',
});

sub tweet { return $_[0]->title(@_) }

sub as_html {
    my $event = shift;
    my $stream = $event->registry_entry or return '';
    return MT->translate($stream->{html_form} || '',
        MT::Util::encode_html($event->author->nickname),
        MT::Util::encode_html( $event->url ),
        $event->autolink( MT::Util::encode_html( $event->title ) ) );
}

1;
