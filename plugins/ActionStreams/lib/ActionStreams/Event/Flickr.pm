
package ActionStreams::Event::Flickr;

use strict;
use base qw( ActionStreams::Event );

__PACKAGE__->install_properties({
    class_type => 'flickr_favorites',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        by
    ) ],
});

my $api_key = q(cbafba81adaad2d40a927c885c47aadf);

sub as_html {
    my $event = shift;
    return MT->translate('[_1] saved <a href="[_2]">[_3]</a> as a favorite photo',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( url title ));
}

sub ident_to_nsid {
    my ($cb, $app, $author, $profile) = @_;
    my $ident = $profile->{ident};

    return 1 if $ident =~ m{ \@ .{3} \z }xms;

    my $url = "http://api.flickr.com/services/rest/"
        . "?method=flickr.people.findByUsername"
        . "&username=$ident&api_key=$api_key"
        ;
    my $ids = __PACKAGE__->fetch_xpath(
        url     => $url,
        foreach => q(//rsp[@stat='ok']),
        get => {
            user_id => 'user/@id',
        },
    );
    return if !$ids;
    my ($id) = @$ids;
    return if !$id->{user_id};
    $profile->{ident} = $id->{user_id};
    1;
}

sub photo_data_for_list_item {
    my $class = shift;
    my %profile = @_;
    my ($author, $item) = @profile{qw( author item )};

    # Preempt if an event already exists.
    my ($old_item) = $class->search({
        author_id  => $author->id,
        identifier => $item->{id},
    });
    return if $old_item;

    my $url = "http://api.flickr.com/services/rest/"
        . "?method=flickr.photos.getInfo"
        . "&api_key=$api_key&photo_id=" . $item->{id}
        ;
    my $photos = $class->fetch_xpath(
        url => $url,
        foreach => '//photo',
        get => {
            title => 'title/child::text()',
            url   => q(urls/url[@type='photopage']/child::text()),
            by    => 'owner/@username',
            tags  => q(tags/tag/@raw),
        },
    );
    return if !$photos;
    my ($photo) = @$photos;
    $photo->{identifier} = $item->{id};

    if ($item->{farm} && $item->{server} && $item->{secret}) {
        $photo->{thumbnail} = 'http://farm' . $item->{farm}
            . '.static.flickr.com/' . $item->{server} . '/' . $item->{id} . '_'
            . $item->{secret} . '_t.jpg';
    }

    return $photo;
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $url = "http://api.flickr.com/services/rest/"
            . "?method=flickr.favorites.getPublicList"
            . "&api_key=$api_key&user_id=$ident"
            ;
    my $items = $class->fetch_xpath(
        url     => $url,
        foreach => q(//photo[@ispublic='1']),
        get => {
            id     => '@id',
            secret => '@secret',
            server => '@server',
            farm   => '@farm',
        },
    );
    return if !$items;

    my @photos = grep { defined }
        map { $class->photo_data_for_list_item( author => $author, item => $_ ) }
        @$items;

    $class->build_results( author => $author, items => \@photos );
}

1;
