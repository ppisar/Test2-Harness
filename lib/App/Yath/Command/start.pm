package App::Yath::Command::start;
use strict;
use warnings;

our $VERSION = '0.001009';

use File::Spec();

use POSIX ":sys_wait_h";
use Time::HiRes qw/sleep/;

use App::Yath::Util qw/find_pfile PFILE_NAME/;
use Test2::Harness::Util qw/open_file/;

use Test2::Harness::Run::Runner::Persist;
use Test2::Harness::Util::File::JSON;

use parent 'App::Yath::Command';
use Test2::Harness::Util::HashBase;

sub group { 'persist' }

sub has_jobs    { 1 }
sub has_runner  { 1 }
sub has_logger  { 0 }
sub has_display { 0 }
sub always_keep_dir { 1 }
sub manage_runner { 0 }

sub summary { "Start the persistent test runner" }
sub cli_args { "" }

sub description {
    return <<"    EOT";
TODO FIX ME
    EOT
}

sub run {
    my $self = shift;

    $self->pre_run();

    if (my $exists = find_pfile()) {
        die "Persistent harness appears to be running, found $exists\n"
    }

    my $settings = $self->{+SETTINGS};
    my $pfile = File::Spec->rel2abs(PFILE_NAME());

    my ($exit, $runner, $pid, $stat);
    my $ok = eval {
        my $run = $self->make_run_from_settings(finite => 0, keep_dir => 1);

        $runner = Test2::Harness::Run::Runner::Persist->new(
            dir => $settings->{dir},
            run => $run,
        );

        my $queue = $runner->queue;
        $queue->start;

        $pid = $runner->spawn(setsid => 1, pfile => $pfile);

        1;
    };
    my $err = $@;

    my $sig = $self->{+SIGNAL};

    print STDERR $err if !$ok && !$sig;
    print STDERR "Received SIG$sig\n" if $sig;

    print "Waiting for runner...\n";

    my $stdout = open_file($runner->out_log);
    my $stderr = open_file($runner->err_log);

    my $check = waitpid($pid, WNOHANG);
    until($runner->ready || $check) {
        while(my $line = <$stdout>) {
            print STDOUT $line;
        }
        while (my $line = <$stderr>) {
            print STDERR $line;
        }
        sleep 0.02;
        $check = waitpid($pid, WNOHANG);
    }

    if ($check != 0) {
        my $exit = $?;
        my $sig = $? & 127;
        $exit >>= 8;
        print STDERR "\nProblem with runner ($pid), waitpid returned $check, exit value: $exit Signal: $sig\n";

        while( my $line = <$stdout> ) {
            print STDOUT $line;
        }
        while (my $line = <$stderr>) {
            print STDERR $line;
        }
    }
    else {
        print "\nPersistent runner started!\n";

        print "Runner PID: $pid\n";
        print "Runner dir: $settings->{dir}\n";
        print "Runner logs:\n";
        print "  standard output: " . $runner->out_log. "\n";
        print "  standard  error: " . $runner->err_log. "\n";
        print "\nUse `yath watch` to monitor the persistent runner\n\n";

        my $data = {
            pid => $pid,
            dir => $settings->{dir},
        };

        Test2::Harness::Util::File::JSON->new(name => $pfile)->write($data);
    }

    return $sig ? 255 : ($exit || 0);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Yath::Command::persist

=head1 DESCRIPTION

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut