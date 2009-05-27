# Movable Type (r) (C) 2001-2008 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id: nl.pm 99820 2009-03-09 13:55:28Z mschenk $

package ActionStreams::L10N::nl;

use strict;
use base 'ActionStreams::L10N::en_us';
use vars qw( %Lexicon );
%Lexicon = (
## plugins/ActionStreams/blog_tmpl/sidebar.mtml

## plugins/ActionStreams/blog_tmpl/main_index.mtml

## plugins/ActionStreams/blog_tmpl/actions.mtml
	'Recent Actions' => 'Recente acties',

## plugins/ActionStreams/blog_tmpl/archive.mtml

## plugins/ActionStreams/blog_tmpl/banner_footer.mtml

## plugins/ActionStreams/blog_tmpl/elsewhere.mtml
	'Find [_1] Elsewhere' => 'Elders [_1] vinden',

## plugins/ActionStreams/streams.yaml
	'Currently Playing' => 'Nu aan het spelen',
	'The games in your collection you\'re currently playing' => 'De spelletjes in uw collectie die u momenteel aan het spelen bent',
	'Comments you have made on the web' => 'Reacties die u elders op het web heeft achtergelaten',
	'Colors' => 'Kleuren',
	'Colors you saved' => 'Kleuren die u heeft opgeslagen',
	'Palettes' => 'Paletten',
	'Palettes you saved' => 'Paletten die u heeft opgeslagen',
	'Patterns' => 'Patronen',
	'Patterns you saved' => 'Patronen die u heeft opgeslagen',
	'Favorite Palettes' => 'Favoriete paletten',
	'Palettes you saved as favorites' => 'Paletten die u heeft opgeslagen als favorieten',
	'Reviews' => 'Besprekingen',
	'Your wine reviews' => 'Uw wijnbesprekingen',
	'Cellar' => 'Kelder',
	'Wines you own' => 'Wijnen die u bezit',
	'Shopping List' => 'Boodschappenlijstje',
	'Wines you want to buy' => 'Wijnen die u wenst te kopen',
	'Links' => 'Links',
	'Your public links' => 'Uw publieke links',
	'Dugg' => 'Dugg',
	'Links you dugg' => 'Links die u \'dugg\' op Digg',
	'Submissions' => 'Ingediend',
	'Links you submitted' => 'Links die u indiende',
	'Found' => 'Gevonden',
	'Photos you found' => 'Foto\'s die u vond',
	'Favorites' => 'Favorieten',
	'Photos you marked as favorites' => 'Foto\'s die u aanmerkte als favorieten',
	'Photos' => 'Foto\'s',
	'Photos you posted' => 'Foto\'s die u publiceerde',
	'Likes' => 'Geappreciëerd',
	'Things from your friends that you "like"' => 'Dingen van uw vrienden die u appreciëerde',
	'Leaderboard scores' => 'Scores in de rangschikkingen',
	'Your high scores in games with leaderboards' => 'Uw hoogste score in spelletjes met een rangschikking',
	'Posts' => 'Berichten',
	'Blog posts about your search term' => 'Blogberichten over uw zoekterm',
	'Stories' => 'Nieuws',
	'News Stories matching your search' => 'Nieuwsberichten over uw zoekterm',
	'To read' => 'Te lezen',
	'Books on your "to-read" shelf' => 'Boeken op uw \'te lezen\' boekenplank',
	'Reading' => 'Aan het lezen',
	'Books on your "currently-reading" shelf' => 'Boeken op uw \'momenteel aan het lezen\' boekenplank',
	'Read' => 'Gelezen',
	'Books on your "read" shelf' => 'Boeken op uw \'gelezen\' boekenplank',
	'Shared' => 'Gedeeld',
	'Your shared items' => 'Uw gedeelde items',
	'Deliveries' => 'Leveringen',
	'Icon sets you were delivered' => 'Icoonsets die u geleverd werden',
	'Notices' => 'Berichtjes',
	'Notices you posted' => 'Berichtjes die u plaatste',
	'Intas' => 'Intas',
	'Links you saved' => 'Links die u bewaarde',
	'Photos you posted that were approved' => 'Foto\'s die u publiceerde en die werden goedgekeurd',
	'Recent events' => 'Recente gebeurtenissen',
	'Events from your recent events feed' => 'Gebeurtenissen uit uw feed met recente gebeurtenissen',
	'Apps you use' => 'Applicaties die u gebruikt',
	'The applications you saved as ones you use' => 'De applicaties die u heeft opgeslagen als applicaties die u gebruikt',
	'Videos you saved as watched' => 'Video\'s die u heeft opgeslagen als bekeken',
	'Jaikus' => 'Jaikus',
	'Jaikus you posted' => 'Jaikus die u publiceerde',
	'Games you saved as favorites' => 'Spelletjes die u heeft opgeslagen als favorieten',
	'Achievements' => 'Mijlpalen',
	'Achievements you won' => 'Mijlpalen die u bereikt heeft',
	'Tracks' => 'Tracks',
	'Songs you recently listened to (High spam potential!)' => 'Liedjes waar u recent naar geluisterd heeft (hoge kans op spam!)',
	'Loved Tracks' => 'Geliefde tracks',
	'Songs you marked as "loved"' => 'Tracks waarvan u heeft aangegeven dat u ervan houdt',
	'Journal Entries' => 'Dagboekberichten',
	'Your recent journal entries' => 'Uw laatste berichten uit uw dagboek',
	'Events' => 'Gebeurtenissen',
	'The events you said you\'ll be attending' => 'De evenementen waarvan u gezegd hebt dat u er zal zijn',
	'Your public posts to your journal' => 'Uw publieke berichten op uw dagboek',
	'Queue' => 'Wachtrij',
	'Movies you added to your rental queue' => 'Films toegevoegd aan uw huurwachtrij',
	'Recent Movies' => 'Recente films',
	'Recent Rental Activity' => 'Recente huuractiviteit',
	'Kudos' => 'Kudos',
	'Kudos you have received' => 'Kudos die u heeft ontvangen',
	'Favorite Songs' => 'Favoriete liedjes',
	'Songs you marked as favorites' => 'Liedjes die u heeft aangemerkt als favorieten',
	'Favorite Artists' => 'Favoriete artiesten',
	'Artists you marked as favorites' => 'Artiesten die u heeft aangemerkt als favorieten',
	'Stations' => 'Zenders',
	'Radio stations you added' => 'Radiozenders die u heeft toegevoegd',
	'List' => 'Lijst',
	'Things you put in your list' => 'Dingen die u in uw lijst heeft gezet',
	'Notes' => 'Berichtjes',
	'Your public notes' => 'Uw publieke berichtjes',
	'Comments you posted' => 'Reacties die u gepubliceerd heeft',
	'Articles you submitted' => 'Artikels die u heeft ingediend',
	'Articles you liked (your votes must be public)' => 'Artikels die u heeft aangemerkt als favorieten',
	'Dislikes' => 'Afgekeurd',
	'Articles you disliked (your votes must be public)' => 'Artikels waar u een afkeer voor heeft laten blijken (stemmen moeten publiek zijn)',
	'Slideshows you saved as favorites' => 'Diavoorstellingen die u als favorieten heeft opgeslagen',
	'Slideshows' => 'Diavoorstellingen',
	'Slideshows you posted' => 'Diavoorstellingen die u publiceerde',
	'Your achievements for achievement-enabled games' => 'Uw mijlpalen in spelletjes die mijlpalen hebben',
	'Stuff' => 'Dinges',
	'Things you posted' => 'Dingen die u publiceerde',
	'Tweets' => 'Tweets',
	'Your public tweets' => 'Uw publieke tweets',
	'Public tweets you saved as favorites' => 'Publieke tweets die u opgeslagen heeft als favorieten',
	'Tweets about your search term' => 'Tweets over uw zoekterm',
	'Saved' => 'Opgeslagen',
	'Things you saved as favorites' => 'Dingen die u heeft opgeslagen als favorieten',
	'Events you are watching or attending' => 'Evenementen die u bekijkt of bijwoont',
	'Videos you posted' => 'Video\'s die u publiceerde',
	'Videos you liked' => 'Video\'s die u goed vond',
	'Public assets you saved as favorites' => 'Publieke mediabestanden die u opsloeg als favorieten',
	'Your public photos in your Vox library' => 'Uw publieke foto\'s in uw Vox bibliotheek',
	'Your public posts to your Vox' => 'Uw publieke berichten op uw Vox',
	'The posts available from the website\'s feed' => 'De berichten beschikbaar op de feed van de website',
	'Wists' => 'Wists',
	'Stuff you saved' => 'Dingen die u opsloeg',
	'Gamerscore' => 'Gamerscore',
	'Notes when your gamerscore passes an even number' => 'Berichtjes over wanneer uw gamerscore een even getal passeert',
	'Places you reviewed' => 'Plaatsen die u heeft besproken',
	'Videos you saved as favorites' => 'Video\'s die u heeft opgeslagen als favorieten',

## plugins/ActionStreams/services.yaml
	'1up.com' => '1up.com',
	'43Things' => '43Things',
	'Screen name' => 'Nickname',
	'backtype' => 'backtype',
	'Bebo' => 'Bebo',
	'Catster' => 'Catster',
	'COLOURlovers' => 'COLOURlovers',
	'Cork\'\'d\'' => 'Cork\'\'d\'',
	'Delicious' => 'Delicious',
	'Destructoid' => 'Destructoid',
	'Digg' => 'Digg',
	'Dodgeball' => 'Dodgeball',
	'Dogster' => 'Dogster',
	'Dopplr' => 'Dopplr',
	'Facebook' => 'Facebook',
	'User ID' => 'Gebruikers ID',
	'You can find your Facebook userid within your profile URL.  For example, http://www.facebook.com/profile.php?id=24400320.' => 'U kunt uw Facebook userid terugvinden in de URL van uw profiel.  Bijvoorbeeld, http://www.facebook.com/profile.php?id=24400320.',
	'FFFFOUND!' => 'FFFFOUND',
	'Flickr' => 'Flickr',
	'Enter your Flickr userid which contains "@" in it, e.g. 36381329@N00.  Flickr userid is NOT the username in the URL of your photostream.' => 'Vul uw Flickr userid in (dit bevat een "@", bijvoorbeeld 36381329@N00). Het Flickr userid is niet de gebruikersnaam in uw photostream',
	'FriendFeed' => 'FriendFied',
	'Gametap' => 'Gametap',
	'Google Blogs' => 'Google Blogs',
	'Search term' => 'Zoekterm',
	'Google News' => 'Google News',
	'Search for' => 'Zoeken naar',
	'Goodreads' => 'Goodreads',
	'You can find your Goodreads userid within your profile URL. For example, http://www.goodreads.com/user/show/123456.' => 'U kunt uw Goodreads userid vinden in de URL van uw profiel.  Bijvoorbeeld http://www.goodreads.com/user/show/123456.',
	'Google Reader' => 'Google Reader',
	'Sharing ID' => 'Sharing ID',
	'Hi5' => 'Hi5',
	'IconBuffet' => 'IconBuffet',
	'ICQ' => 'ICQ',
	'UIN' => 'UIN',
	'Identi.ca' => 'Identi.ca',
	'Iminta' => 'Iminta',
	'iStockPhoto' => 'iStockPhoto',
	'You can find your istockphoto userid within your profile URL.  For example, http://www.istockphoto.com/user_view.php?id=1234567.' => 'U kunt uw iStockPhoto userid vinden in de URL van uw profiel.  Bijvoorbeeld, http://www.istockphoto.com/user_view.php?id=1234567.',
	'IUseThis' => 'iUseThis',
	'iwatchthis' => 'iwatchthis',
	'Jabber' => 'Jabber',
	'Jabber ID' => 'Jabber ID',
	'Jaiku' => 'Jaiku',
	'Kongregate' => 'Kongregate',
	'Last.fm' => 'Last.fm',
	'LinkedIn' => 'LinkedIn',
	'Profile URL' => 'URL van profiel',
	'Ma.gnolia' => 'Ma.gnolia',
	'MOG' => 'MOG',
	'MSN Messenger\'' => 'MSN Messenger',
	'Multiply' => 'Multiply',
	'MySpace' => 'MySpace',
	'Netflix' => 'Netflix',
	'Netflix RSS ID' => 'Netflix RSS ID',
	'To find your Netflix RSS ID, click "RSS" at the bottom of any page on the Netflix site, then copy and paste in your "Queue" link.' => 'Om uw Netflix RSS ID terug te vinden, moet u op "RSS" klikken onderaan éénder welke pagina op de Netflix site en dan uw "Queue" link knippen en plakken.',
	'Netvibes' => 'Netvibes',
	'Newsvine' => 'Newsvine',
	'Ning' => 'Ning',
	'Social Network URL' => 'Sociaal netwerk URL',
	'Ohloh' => 'Ohloh',
	'Orkut' => 'Orkut',
	'You can find your orkut uid within your profile URL. For example, http://www.orkut.com/Main#Profile.aspx?rl=ls&uid=1234567890123456789' => 'U kunt uw Orkut uid terugvinden in de URL van uw profiel.  Bijvoorbeeld, http://www.orkut.com/Main#Profile.aspx?rl=ls&uid=1234567890123456789',
	'Pandora' => 'Pandora',
	'Picasa Web Albums' => 'Picasa Web Albums',
	'p0pulist' => 'p0pulist',
	'You can find your p0pulist user id within your Hot List URL. for example, http://p0pulist.com/list/hot_list/10000' => 'U kunt uw p0pulist userid terugvinden in de URL van uw Hot List.  Bijvoorbeeld, http://p0pulist.com/list/hot_list/10000',
	'Pownce' => 'Pownce',
	'Reddit' => 'Reddit',
	'Skype' => 'Skype',
	'SlideShare' => 'SlideShare',
	'Smugmug' => 'Smugmug',
	'SonicLiving' => 'SonicLiving',
	'You can find your SonicLiving userid within your share&subscribe URL. For example, http://sonicliving.com/user/12345/feeds' => 'U kunt uw SonicLiving userid vinden in uw share&subscribe URL.  Bijvoorbeeld, http://sonicliving.com/user/12345/feeds',
	'Steam' => 'Steam',
	'StumbleUpon' => 'StumbleUpon',
	'Tabblo' => 'Tabblo',
	'Blank should be replaced by positive sign (+).' => 'Blank moet vervangen worden met een plusteken (+)',
	'Tribe' => 'Tribe',
	'You can find your tribe userid within your profile URL.  For example, http://people.tribe.net/dcdc61ed-696a-40b5-80c1-e9a9809a726a.' => 'U kunt uw tribe userid terugvingen in de URL van uw profiel.  Bijvoorbeeld, http://people.tribe.net/dcdc61ed-696a-40b5-80c1-e9a9809a726a.',
	'Tumblr' => 'Tumblr',
	'Twitter' => 'Twitter',
	'TwitterSearch' => 'TwitterSearch',
	'Uncrate' => 'Uncrate',
	'Upcoming' => 'Upcoming',
	'Viddler' => 'Viddler',
	'Vimeo' => 'Vimeo',
	'Virb' => 'Virb',
	'You can find your VIRB userid within your home URL.  For example, http://www.virb.com/backend/2756504321310091/your_home.' => 'U kunt uw VIRB userid in uw home URL terugvinden.  Bijvoorbeeld, http://www.virb.com/backend/2756504321310091/your_home.',
	'Vox name' => 'Vox-naam',
	'Website' => 'Website',
	'Xbox Live\'' => 'Xbox Live\'',
	'Gamertag' => 'Gamertag',
	'Yahoo! Messenger\'' => 'Yahoo! Messenger\'',
	'Yelp' => 'Yelp',
	'YouTube' => 'YouTube',
	'Zooomr' => 'Zooomr',

## plugins/ActionStreams/config.yaml
	'Manages authors\' accounts and actions on sites elsewhere around the web' => 'Beheert account en acties van de auteurs elders op het web',
	'Are you sure you want to hide EVERY event in EVERY action stream?' => 'Bent u zeker dat u ELKE gebeurtenis in ELKE action stream wenst te verbergen?',
	'Are you sure you want to show EVERY event in EVERY action stream?' => 'Bent u zeker dat u ELKE gebeurtenis in ELKE action stream wenst te tonen?',
	'Deleted events that are still available from the remote service will be added back in the next scan. Only events that are no longer available from your profile will remain deleted. Are you sure you want to delete the selected event(s)?' => 'Verwijderde gebeurtenissen die nog steeds beschikbaar zijn via de externe service zullen opnieuw worden toegevoegd bij de volgende scan. Enkel gebeurtenissen die niet meer op uw profiel voorkomen zullen verwijderd blijven.  Bent u zeker dat u de geselecteerde gebeurtenis(sen) wenst te verwijderen?',
	'Hide All' => 'Alles verbergen',
	'Show All' => 'Alles tonen',
	'Poll for new events' => 'Checken voor nieuwe gebeurtenissen',
	'Update Events' => 'Gebeurtenissen bijwerken',
	'Action Stream' => 'Action Stream',
	'Main Index (Recent Actions)' => 'Hoofdindex (recente acties)',
	'Action Archive' => 'Actie-archief',
	'Feed - Recent Activity' => 'Feed - Recente activiteit',
	'Find Authors Elsewhere' => 'Elders auteurs vinden',
	'Enabling default action streams for selected profiles...' => 'Standaard action streams inschakelen voor geselecteerde profielen...',

## plugins/ActionStreams/lib/ActionStreams/Upgrade.pm
	'Updating classification of [_1] [_2] actions...' => 'Classificatie bij aan het werken voor [_1] [_2] acties...',
	'Renaming "[_1]" data of [_2] [_3] actions...' => '"[_1] gegevens van [_2] [_3] acties een nieuwe naam aan het geven...',

## plugins/ActionStreams/lib/ActionStreams/Worker.pm
	'No such author with ID [_1]' => 'Geen auteur gevonden met ID [_1]',

## plugins/ActionStreams/lib/ActionStreams/Plugin.pm
	'Other Profiles' => 'Andere profielen',
	'Profiles' => 'Profielen',
	'Actions from the service [_1]' => 'Gebeurtenissen op service [_1]',
	'Actions that are shown' => 'Gebeurtenissen die worden weergegeven',
	'Actions that are hidden' => 'Gebeurtenissen die worden verborgen',
	'No such event [_1]' => 'Geen [_1] evenement gevonden',
	'[_1] Profile' => '[_1] profiel',

## plugins/ActionStreams/lib/ActionStreams/Tags.pm
	'No user [_1]' => 'Geen gebruiker [_1]',

## plugins/ActionStreams/lib/ActionStreams/Event.pm
	'[_1] updating [_2] events for [_3]' => '[_1] [_2] evenementen aan het bijwerken voor [_3]',
	'Error updating events for [_1]\'s [_2] stream (type [_3] ident [_4]): [_5]' => 'Fout bij het updaten van evenementen voor [_1]\'s [_2] stream (type [_3] ident [_4]: [5]',
	'Could not load class [_1] for stream [_2] [_3]: [_4]' => 'Kon klasse [_1] voor stream [_2] [_3] niet laden: [_4]',
	'No URL to fetch for [_1] results' => 'Geen URL binnen te halen voor [_1] resultaten', # Translate - New
	'Could not fetch [_1]: [_2]' => 'Kon [_1] niet binnenhalen: [_2]', # Translate - New
	'Aborted fetching [_1]: [_2]' => 'Ophalen [_1] geannuleerd: [_2]', # Translate - New

## plugins/ActionStreams/tmpl/dialog_edit_profile.tmpl
	'Your user name or ID is required.' => 'Uw gebruikersnaam of ID is vereist.',
	'Edit a profile on a social networking or instant messaging service.' => 'Bewerk een profiel op een sociaal netwerk of instant messaging dienst.',
	'Service' => 'Service',
	'Enter your account on the selected service.' => 'Vul uw account op de geselecteerde service in.',
	'For example:' => 'Bijvoorbeeld:',
	'Action Streams' => 'Action Streams',
	'Select the action streams to collect from the selected service.' => 'Selecteer de action streams die opgehaald moeten worden van de geselecteerde service.',
	'No streams are available for this service.' => 'Geen streams beschikbaar van deze service',

## plugins/ActionStreams/tmpl/other_profiles.tmpl
	'The selected profile was added.' => 'Het geselecteerde profiel werd toegevoegd.',
	'The selected profiles were removed.' => 'De geselecteerde profielen werden verwijderd.',
	'The selected profiles were scanned for updates.' => 'De geselecteerde profielen werden gescand op updates.',
	'The changes to the profile have been saved.' => 'De wijzigingen aan het profiel werden opgeslagen.',
	'Add Profile' => 'Prfiel toevoegen',
	'profile' => 'profiel',
	'profiles' => 'profielen',
	'Delete selected profiles (x)' => 'Geselecteerde profielen verwijderen (x)',
	'to update' => 'om bij te werken',
	'Scan now for new actions' => 'Nu scannen op nieuwe gebeurtenissen',
	'Update Now' => 'Nu bijwerken',
	'No profiles were found.' => 'Geen profielen gevonden',
	'external_link_target' => 'external_link_target',
	'View Profile' => 'Profiel bekijken',

## plugins/ActionStreams/tmpl/dialog_add_profile.tmpl
	'Add a profile on a social networking or instant messaging service.' => 'Voeg een profiel toe op een sociaal netwerk of een instant messaging dienst.',
	'Select a service where you already have an account.' => 'Selecteer een service waar u reeds een account heeft.',
	'Add Profile (s)' => 'Profiel Toevoegen (s)', # Translate - New

## plugins/ActionStreams/tmpl/list_profileevent.tmpl
	'The selected events were deleted.' => 'De geselecteerde gebeurtenissen werden verwijderd.',
	'The selected events were hidden.' => 'De geselecteerde gebeurtenissen werden verborgen.',
	'The selected events were shown.' => 'De geselecteerde gebeurtenissen werden weergegeven.',
	'All action stream events were hidden.' => 'Alle actions streams gebeurtenissen werden verborgen.',
	'All action stream events were shown.' => 'Alle action stream gebeurtenissen werden weergegeven.',
	'event' => 'gebeurtenis',
	'events' => 'gebeurtenissen',
	'Hide selected events (h)' => 'Geselecteerde gebeurtenissen verbergen (h)',
	'Hide' => 'Verbergen',
	'Show selected events (h)' => 'Geselecteerde gebeurtenissen tonen (h)',
	'Show' => 'Tonen',
	'All stream actions' => 'Alle gebeurtenissen van de stream',
	'Show only actions where' => 'Enkel gebeurtenissen tonen waar',
	'service' => 'service',
	'visibility' => 'zichtbaarheid',
	'hidden' => 'verborgen',
	'shown' => 'zichtbaar',
	'No events could be found.' => 'Er werden geen gebeurtenissen gevonden.',
	'Event' => 'Gebeurtenis',
	'Shown' => 'Zichtbaar',
	'Hidden' => 'Verborgen',
	'View action link' => 'Actielink bekijken',

## plugins/ActionStreams/tmpl/widget_recent.mtml
	'Your Recent Actions' => 'Uw recente acties',
	'blog this' => 'blog dit',

## plugins/ActionStreams/tmpl/blog_config_template.tmpl
	'Rebuild Indexes' => 'Indexen herpubliceren',
	'If selected, this blog\'s indexes will be rebuilt when new action stream events are discovered.' => 'Indien geselecteerd zullen de indexen van deze blog opnieuw worden gepubliceerd telkens nieuwe action stream gebeurtenissen worden ontdekt.',
	'Enable rebuilding' => 'Herpubliceren toestaan',
);

1;
