
package ActionStreams::Event::Twitter;

use strict;
use base qw( ActionStreams::Event );

sub autolink {
    my $self = shift;
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
    $text =~ s{(\s|^)#([A-Za-z0-9_]+)}{$1#<a href="http://summize.com/search?tag=$2">$2</a>}gs;  

    return $text;
}

1;

