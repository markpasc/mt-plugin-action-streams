
package ActionStreams::Event::Netflix;

use strict;
use base qw( ActionStreams::Event );

__PACKAGE__->install_properties({
    class_type => 'netflix_shipped',
});

__PACKAGE__->install_meta({
    columns => [ qw(
        description
    ) ],
});

sub as_html {
    my $event = shift;
    return MT->translate('[_1] received the DVD <a href="[_2]">[_3]</a>',
        MT::Util::encode_html($event->author->nickname),
        map { MT::Util::encode_html($event->$_()) } qw( url title ));
}

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $items = $class->fetch_xpath(
        url     => "http://rss.netflix.com/TrackingRSS?id=$ident",
        foreach => '//item',
        get => {
            title       => 'title/child::text()',
            url         => 'link/child::text()',
            description => 'description/child::text()',
        },
    );
	return if !$items;
    
    ITEM: for my $item (@$items) {
        next ITEM if $item->{title} =~ m{ \A Shipped }xms;
        $item->{title} =~ s{ \A Shipped: \s }{}xms;
        
        (undef, $item->{description}) = split /\n/, $item->{description};
        
        my ($old_event) = $class->search({
            author_id  => $author->id,
            identifier => $item->{url},
        });
        next ITEM if $old_event;
        
        my $event = $class->new;
        $event->set_values({
            author_id  => $author->id,
            identifier => $item->{url},
            %$item,
        });
        $event->save() or MT->log($event->errstr);
    }

    1;
}

1;
