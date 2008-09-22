
package ActionStreams::Event::Twitter;

use strict;

use MT::Util qw( encode_url );

sub profile_link_for_name {
    my $self = shift;
    my ($name) = @_;
    return qq{<a href="http://twitter.com/$name">$name</a>};
}

sub search_link_for_tag {
    my $self = shift;
    my ($tag) = @_;
    my $enc_tag = encode_url($tag);
    return qq{<a href="http://search.twitter.com/search?tag=$enc_tag">$tag</a>};
}

sub autolink {
    my $self = shift;
    my ($text) = @_;
    return '' unless defined $text;

    # autolink URLs
    $text =~ s{
        ( \A | [\s.:;?\-\]<\(] )
        (
            https?://
            [-\w;/?:@&=+\$\.!~*'()%,#]+
            [\w/]
        )
        (?= \z | [\s\.,!:;?\-\[\]>\)] )
    }{$1<a href="$2">$2</a>}xmsg;

    # twitter ids (@bradchoate)
    $text =~ s{
        (?: (?<= \A @ )    # leading @
          | (?<= \s @ ) )  # or space and @
        (\w+)              # and a name
    }{ $self->profile_link_for_name($1) }xmsge;

    # hash tags (#perl)
    $text =~ s{
        (?: (?<= \A\# ) | (?<= \s\# ) )  # BOT or whitespace
        (\w\S*\w)      # tag
        (?<! 's )      # but don't end with 's
    }{ $self->search_link_for_tag($1) }xmsge;

    return $text;
}

1;
