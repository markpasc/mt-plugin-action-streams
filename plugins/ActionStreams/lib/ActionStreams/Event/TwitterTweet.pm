package ActionStreams::Event::TwitterTweet;

use strict;
use base qw( ActionStreams::Event );

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
        autolink( MT::Util::encode_html( $event->tweet ) ) );
}

sub autolink {
    my ($text) = @_;
    return '' unless defined $text;

    # autolink URLs
    $text =~ s{
        ( ^ | [\s.:;?\-\]<\(] )
        (
            https?://
            [-\w;/?:@&=+$\.!~*'()%,#]+
            [\w/]
        )
        (?= $ | [\s\.,!:;?\-\[\]>\)] )
    }{$1<a href="$2">$2</a>}gmx;

    # twitter ids (@bradchoate)
    $text =~ s{(\s|^)@([A-Za-z0-9_]+)}{$1@<a href="http://www.twitter.com/$2">$2</a>}gs;

    # hash tags (#perl) (linking to summize requests)
    $text =~ s{(\s|^)#([A-Za-z0-9_]+)}{$1#<a href="http://www.summize.com/search?tag=$2">$2</a>}gs;  

    return $text;
}

1;

