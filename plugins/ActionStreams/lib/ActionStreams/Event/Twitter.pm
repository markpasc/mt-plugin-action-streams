
package ActionStreams::Event::Twitter;

use strict;

use MT::Util qw( encode_url );

sub profile_link_for_name {
    my $self = shift;
    my ($name) = @_;
    my ($type, $stream) = split /_/, $self->properties->{class_type}, 2;

    my $services = MT->instance->registry('profile_services')
        or return $name;
    my $service = $services->{$type}
        or return $name;
    my $url = $service->{url}
        or return $name;

    $url =~ s{ (?:\%s|\Q{{ident}}\E) }{$name}xmsg;
    return qq{<a href="$url">$name</a>};
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
    return q{} unless defined $text;

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

sub encode_and_autolink_title_field {
    my $event = shift;
    my ($field) = @_;
    my $value = ActionStreams::Event::encode_field_for_html($event, @_);
    return $field eq 'title' ? $event->autolink($value) : $value;
}

1;
