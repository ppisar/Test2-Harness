package App::Yath::Command::ps;
use strict;
use warnings;

our $VERSION = '1.000096';

use Term::Table();
use File::Spec();

use App::Yath::Util qw/find_pfile/;

use Test2::Harness::Runner::State;
use Test2::Harness::Util::File::JSON();
use Test2::Harness::Util::Queue();

use parent 'App::Yath::Command::status';
use Test2::Harness::Util::HashBase qw/queue/;

sub group { 'persist' }

sub summary { "Process list for the runner" }
sub cli_args { "" }

sub description {
    return <<"    EOT";
List all running processes and runner stages.
    EOT
}

sub run {
    my $self = shift;

    my $pfile = find_pfile($self->settings)
        or die "No persistent harness was found for the current path.\n";

    print "\nFound: $pfile\n";
    my $data = Test2::Harness::Util::File::JSON->new(name => $pfile)->read();
    print "  PID: $data->{pid}\n";
    print "  Dir: $data->{dir}\n";

    my $state = Test2::Harness::Runner::State->new(
        job_count    => 1,
        workdir      => $self->workdir,
    );

    $state->poll;

    my @jobs;

    my $stage_status = $state->stage_readiness // {};
    for my $stage (keys %$stage_status) {
        my $pid = $stage_status->{$stage} // next;
        $pid = 'N/A' if $pid == 1;
        push @jobs => [$pid, "Runner Stage", $stage];
    }

    my $running = $state->running_tasks;
    for my $task (values %$running) {
        my $pid = $self->get_job_pid($task->{run_id}, $task->{job_id}) // 'N/A';
        my $file = $task->{rel_file};
        push @jobs => [$pid, "Running Test", $file];
    }

    my $process_table = Term::Table->new(
        collapse => 1,
        header => [qw/pid type name/],
        rows => [sort { $a->[0] <=> $b->[0] } @jobs],
    );

    print "\n**** Running Processes ****\n";
    print "$_\n" for $process_table->render;

    return 0;
}

1;

__END__

=head1 POD IS AUTO-GENERATED
