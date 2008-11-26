
package ActionStreams::Event::Vox;

use strict;
use base qw( ActionStreams::Event );

use ActionStreams::Scraper;

__PACKAGE__->install_properties({
    class_type => 'vox_favorites',
});

sub update_events {
    my $class = shift;
    my %profile = @_;
    my ($ident, $author) = @profile{qw( ident author )};

    my $items = $class->fetch_scraper(
        url => "http://$ident.vox.com/profile/favorites/",
        scraper => scraper {
            process '.asset',
                'assets[]' => scraper {
                    process '.asset',
                        identifier => '@at:xid';
                    process '.asset-meta .asset-name a',
                        url   => '@href',
                        title => 'TEXT';
                };
            result 'assets';
        },
    );
	return if !$items;

    $class->build_results( author => $author, items => $items );
}

1;
