
package ActionStreams::Worker;
use strict;
use warnings;

use base qw( TheSchwartz::Worker );

sub make_work {
    my $class = shift;
    my %profile = @_;

    require MT::TheSchwartz;
    require TheSchwartz::Job;
    my $job = TheSchwartz::Job->new;
    $job->funcname(__PACKAGE__);

    my $event_class = $profile{event_class};
    my $author      = delete $profile{author};
    $profile{author_id} = $author->id;
    $job->uniqkey(join q{:}, $author->id, $profile{ident}, $event_class);

    $job->arg([ %profile ]);
    MT::TheSchwartz->insert($job);
    return $job;
}

sub work {
    my $self = shift;
    my ($job) = @_;
    my %profile = @{ $job->arg };
    my ($author_id, $event_class)
        = delete @profile{qw( author_id event_class )};

    $profile{author} = MT->model('author')->load($author_id);
    if (!$profile{author}) {
        my $plugin = MT->component('ActionStreams');
        my $msg = $plugin->translate('No such author with ID [_1]',
            $author_id);
        return $job->permanent_failure($msg);
    }

    # If the class doesn't exist or isn't an ActionStreams::Event... well,
    # we did all the updating we could, right?
    eval { $event_class->properties && $event_class->can('update_events_loggily') }
        or return $job->completed();

    eval { $event_class->update_events_loggily(%profile); 1 }
        or return $job->permanent_failure($@ || q{});
    return $job->completed();
}

1;
