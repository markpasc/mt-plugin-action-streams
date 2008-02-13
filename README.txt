# Action Streams Plugin for Movable Type
# Author: Mark Paschal
# Copyright 2008 Six Apart, Ltd.
# License: Artistic, licensed under the same terms as Perl itself


OVERVIEW

The Action Streams plugin utilizes Movable Type to monitor a collection of 3rd party web sites
and services for changes to a user's profile. The plugin will then aggregate and collect those
actions so that they can be published to a user's website, blog or profile.

The plugin adds the ability for an author within Movable Type to list their accounts on 3rd
party web sites.  From these accounts, a periodic task automatically imports the author's
activities on those services via RSS, Atom, and some web scraping.  This allows the author to
create an Action Stream completely under their control.

This plugin then provides a set of template tags as well that make it possible to publish and
display the author's accounts and actions on any page powered by Movable Type.  The default
example templates use the Microformats XFN and hAtom to make the information more accessible.


PREREQUISITES

- Movable Type 4.1 or higher
- Scheduled task or cron job to execute the Periodic Tasks script (see below)

The Action Streams plugin ships with all of the external libraries you should need to run it.

Note: Action Streams does not work when run-periodic-tasks is run in daemon mode.


INSTALLATION

  1. Configure a cronjob (see below) for the script run-periodic-tasks.
  2. Unpack the ActionStreams archive.
  3. Copy the contents of ActionStreams/extlib into /path/to/mt/extlib/
  3. Copy the contents of ActionStreams/mt-static into /path/to/mt/mt-static/
  4. Copy the contents of ActionStreams/plugins into /path/to/mt/plugins/
  5. Navigate to your profile, and click on "Other Profiles."
  6. Build a list of your accounts that you wish to display and stream actions from.
  7. Edit your stylesheet to include needed CSS. (see STYLES below)
  8. Edit your templates to display your other profiles and your Action Stream. (see
     example_templates folder)  A template set is also provided for convenience.
  9. Edit the plugin's settings to enable automatically rebuilding your blog as new
     actions are imported.  This setting is under each of your blog's plugin settings.


CRONJOB

Add the following lines to your crontab to execute the script at the hour and 30 minutes
past the hour:

  # Movable Type's scheduled tasks script:
  0,30 * * * * cd /path/to/mt; perl ./tools/run-periodic-tasks


STYLES

To add icons to your Action Streams and other basic styling, add the following line to 
the top of your main stylesheet (normally styles.css). 

  @import url(<MT:StaticWebPath>/plugins/ActionStreams/css/action-streams.css);

The classes used in the template code examples use the same classes as the default templates
and thus they work well with the default themes.


TEMPLATE CODE

The example_templates folder within the Action Streams plugin includes example widgets and
index templates which make use of an author's Other Profiles and Action Stream.  Though it
is possible to create Action Streams combining actions from multiple authors, all of the 
examples display profiles or actions from a single author.

The following template code will produce a list of actions for the author "Melody Nelson":

  <mt:ActionStreams display_name="Melody Nelson" lastn="20">
      <mt:if name="__first__">
  <div class="action-stream">
      <ul class="action-stream">
      </mt:if>
          <li class="service-icon service-<mt:var name="service_type">"><mt:StreamAction></li>
      <mt:if name="__last__">
      </ul>
  </div>
      </mt:if>
  </mt:ActionStreams>

It is recommended that you add the above code as a template module or widget to make it
easier to include and display profile actions throughout your web site.

For more detailed examples see the templates in the example_templates directory.

There are additional template tags, such as mt:StreamActionThumbnailURL, which need to
be documented better in the future.
    <mt:setvarblock name="thumb_url"><mt:StreamActionThumbnailURL></mt:setvarblock>
    <mt:if name="thumb_url">
        <div style='padding-left: 20px; padding-bottom: 10px; padding-top: 5px;'>
            <img src='<mt:var name='thumb_url'>' />
        </div>
    </mt:if>

CREDITS

This distribution contains icons from Silk, an icon set by Mark James,
licensed under the Creative Commons Attribution 2.5 License.

http://www.famfamfam.com/lab/icons/silk/


