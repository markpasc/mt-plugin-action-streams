
package ActionStreams::Worker;
use strict;
use warnings;

use base qw( TheSchwartz::Worker );

sub make_work {
    my $class = shift;
    my %param = @_;
    my ($author, $event_class) = @param{qw( author event_class )};

    $param{author} = $author->deflate();

    require MT::TheSchwartz;
    require TheSchwartz::Job;
    my $job = TheSchwartz::Job->new;
    $job->funcname(__PACKAGE__);
    $job->uniqkey(join q{:}, $author->id, $event_class);
    $job->arg([ %param ]);
    MT::TheSchwartz->insert($job);
}

sub work {
    my $self = shift;
    my ($job) = @_;
    my %profile = @{ $job->arg };
    my ($type, $author, $event_class) = @profile{qw( type author event_class )};
    $profile{author} = MT->model('author')->inflate($author);

    my $warn = $SIG{__WARN__} || sub { print STDERR $_[0] };
    local $SIG{__WARN__} = sub {
        my ($msg) = @_;
        $msg =~ s{ \n \z }{}xms;
        $msg = MT->component('ActionStreams')->translate(
            '[_1] updating [_2] events for [_3]',
            $msg, $type, $profile{author}->name,
        );
        $warn->("$msg\n");
    };

    eval {
        $event_class->update_events(%profile);
    };

    if (my $err = $@) {
        my $plugin = MT->component('ActionStreams');
        my $err_msg = $plugin->translate("Error updating events for [_1]'s [_2] stream (type [_3] ident [_4]): [_5]",
            $profile{author}->name, $event_class->properties->{class_type},
            $profile{type}, $profile{ident}, $err);
        MT->log($err_msg);
        # We'll try again in a half hour anyway, so don't bother retrying.
        return $job->permanent_failure($err_msg);
    }

    return $job->completed();
}

1;
