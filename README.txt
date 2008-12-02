# Action Streams Plugin for Movable Type
# Authors: Mark Paschal, Bryan Tighe, Brad Choate, Alex Bain
# Copyright 2008 Six Apart, Ltd.
# License: Artistic, licensed under the same terms as Perl itself


OVERVIEW

Action Streams for Movable Type collects your action on third party web sites
into your Movable Type web site. Using it, you can aggregate those actions for
your reference, promote specific items to blog posts, and stream the whole set
to your friends and readers. Action Streams are a powerful part of your web
profile.

The plugin adds the ability for your Movable Type authors to list their
accounts on third party web services. A periodic task then automatically
imports your authors' activity on those services using XML feeds (where
provided) and scraping HTML pages (where necessary). Your authors can then
publish their action streams completely under their control: the provided
template tags make it possible to display authors' accounts and actions on any
page powered by Movable Type. The example templates and the provided template
set also use the XFN and hAtom microformats and provide web feeds to integrate
with tools your readers may be using.


PREREQUISITES

- Movable Type 4.2 or higher
- Scheduled task or cron job to execute the Periodic Tasks script (see below)

The Action Streams plugin ships with all of the external libraries you should
need to run it.

Note: Action Streams does not work when run-periodic-tasks is run in daemon
mode.


INSTALLATION

  1. Configure a cronjob (see below) for the script run-periodic-tasks.
  2. Unpack the ActionStreams archive.
  3. Copy the contents of ActionStreams/extlib into /path/to/mt/extlib/
  3. Copy the contents of ActionStreams/mt-static into /path/to/mt/mt-static/
  4. Copy the contents of ActionStreams/plugins into /path/to/mt/plugins/
  5. Navigate to your profile, and click on "Other Profiles."
  6. Build a list of your accounts from which to display and stream actions.
  7. Edit your stylesheet to include needed CSS. (see STYLES below)
  8. Edit your templates to display your other profiles and your Action
     Stream. (See the Template Author Guide in the doc/ folder.) A template
     set is also provided for convenience.
  9. Edit the plugin's settings to enable automatically rebuilding your blog
     as new actions are imported. This setting is under each of your blog's
     plugin settings.


CRONJOB

Action Streams uses Movable Type's scheduled task system to collect your
action data from remote services. To run scheduled tasks, configure a cron job
to run MT's tools/run-periodic-tasks script periodically.

Add the following lines to your crontab to execute the script every 10
minutes:

  # Movable Type scheduled tasks
  */10 * * * * cd /path/to/mt; perl ./tools/run-periodic-tasks


STYLES

To add icons to your Action Streams and other basic styling, add the following
line to the top of your main stylesheet (normally styles.css).

  @import url(<MT:StaticWebPath>plugins/ActionStreams/css/action-streams.css);

The classes used in the template code examples use the same classes as the
default templates and thus they work well with the default themes.


TEMPLATE CODE

See the Template Author Guide in the doc/ folder for help with Action Streams'
template tags.


CHANGES

2.0   30 January 2009
      Wrote documentation (see plugin's doc/ directory or web site).
      Provided editing of external profiles that have already been added.
      Added "Update Now" button to profiles list.
      Hotlinking of Twitter and Identi.ca tweets in default rendering.
      Support for conditional HTTP requests when collecting actions.
      Provided filtering of the "Action Streams" listing in the app.
      Added `StreamActionRollup` tag for "rolling up" similar actions.
      Bundled the "Recent Actions" blog dashboard widget. (Thanks, Bryan!)
      Added support for RSS feeds in the Website stream.
      Provided code to make easy "rss" recipes from RSS feeds.
      Improved template set (incl. fixes for MT 4.2 support).
      Switched to asynchronous job processing for action collecting.
      Made installation easier (less dependent on Web::Scraper, moved extlib
      into plugin as per MT 4.2 capability, removed Iwtst plugin).
      Added many new profiles and streams!

1.0   30 January 2008
      Initial release.


CREDITS

Thanks to Bryan Tighe, Brad Choate, and Alex Bain for their contributions of
various features and stream recipes.

This distribution contains icons from Silk, an icon set by Mark James,
licensed under the Creative Commons Attribution 2.5 License.

http://www.famfamfam.com/lab/icons/silk/


