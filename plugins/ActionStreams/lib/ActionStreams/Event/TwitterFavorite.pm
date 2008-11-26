package ActionStreams::Event::TwitterFavorite;

use strict;
use base qw( ActionStreams::Event ActionStreams::Event::Twitter );

__PACKAGE__->install_properties({
    class_type => 'twitter_favorites',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        tweet_author
    ) ],
});

sub encode_field_for_html {
    return shift->encode_and_autolink_title_field(@_);
}

1;

