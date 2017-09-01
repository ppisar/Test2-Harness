package Test2::Harness::Job::Runner::Fork;
use strict;
use warnings;

our $VERSION = '0.001005';

use Scalar::Util qw/openhandle/;
use Test2::Util qw/clone_io CAN_REALLY_FORK/;
use Test2::Harness::Util qw/write_file/;

sub viable {
    my $class = shift;
    my ($test) = @_;

    return 0 unless CAN_REALLY_FORK();

    return 0 if $ENV{HARNESS_PERL_SWITCHES};

    return 0 if @{$test->switches};

    if (my $headers = $test->headers) {
        return 0 if exists($headers->{features}->{preload}) && !$headers->{features}->{preload};
    }

    return 1;
}

sub run {
    my $class = shift;
    my ($test) = @_;

    my $pid = fork();
    die "Failed to fork: $!" unless defined $pid;

    # In parent
    return ($pid, undef) if $pid;

    # In Child
    my $file = $test->file;

    my $env = $test->env_vars;
    $ENV{$_} = $env->{$_} for keys %$env;

    $ENV{T2_HARNESS_FORKED}  = 1;
    $ENV{T2_HARNESS_PRELOAD} = 1;

    my ($in_file, $out_file, $err_file, $event_file) = $test->output_filenames;

    $0 = $file;
    $class->_reset_DATA($file);
    @ARGV = ();

    # if FindBin is preloaded, reset it with the new $0
    FindBin::init() if defined &FindBin::init;

    # restore defaults
    Getopt::Long::ConfigDefaults() if defined &Getopt::Long::ConfigDefaults;

    # reset the state of empty pattern matches, so that they have the same
    # behavior as running in a clean process.
    # see "The empty pattern //" in perlop.
    # note that this has to be dynamically scoped and can't go to other subs
    "" =~ /^/;

    # Keep a copy of the old STDERR for a while so we can still report errors
    my $stderr = clone_io(\*STDERR);
    my $die = sub { print $stderr @_; exit 255 };

    write_file($in_file, $test->input);

    close(STDIN) or die "Could not close STDIN: $!";
    open(STDIN, '<', $in_file) or die "Could not re-open STDIN";
    die "New STDIN did not get fileno 0!" unless fileno(STDIN) == 0;

    close(STDOUT) or die "Could not close STDOUT: $!";
    open(STDOUT, '>', $out_file) or die "Could not re-open STDOUT";
    die "New STDOUT did not get fileno 1!" unless fileno(STDOUT) == 1;

    # Should get fileno 2
    close(STDERR) or $die->("Could not close STDERR: $!");
    open(STDERR, '>', $err_file) or $die->("Could not re-open STDOUT");
    $die->("New STDERR did not get fileno 2!") unless fileno(STDERR) == 2;

    # avoid child processes sharing the same seed value as the parent
    srand();

    if ($INC{'Test2/API.pm'}) {
        Test2::API::test2_stop_preload();
        Test2::API::test2_post_preload_reset();
    }

    push @INC => @{$test->libs};

    unless ($test->no_stream) {
        $ENV{T2_FORMATTER} = 'Stream';
        require Test2::Formatter::Stream;
        Test2::Formatter::Stream->import(file => $event_file);
    }

    if ($test->times) {
        require Test2::Plugin::Times;
        Test2::Plugin::Times->import();
    }

    @ARGV = @{$test->args};

    return (undef, $file);
}

# Heavily modified from forkprove
sub _reset_DATA {
    my $class = shift;
    my ($file) = @_;

    # open DATA from test script
    if (openhandle(\*main::DATA)) {
        close ::DATA;
        if (open my $fh, $file) {
            my $code = do { local $/; <$fh> };
            if (my ($data) = $code =~ /^__(?:END|DATA)__$(.*)/ms) {
                open ::DATA, '<', \$data
                    or die "Can't open string as DATA. $!";
            }
        }
    }

    for my $set (@{$class->preload_list}) {
        my ($mod, $file, $pos) = @$set;

        my $fh = do {
            no strict 'refs';
            *{$mod . '::DATA'};
        };

        # note that we need to ensure that each forked copy is using a
        # different file handle, or else concurrent processes will interfere
        # with each other

        close $fh if openhandle($fh);

        if (open $fh, '<', $file) {
            seek($fh, $pos, 0);
        }
        else {
            warn "Couldn't reopen DATA for $mod ($file): $!";
        }
    }
}

# Heavily modified from forkprove
sub preload_list {
    my $class = shift;

    my $list = [];

    for my $loaded (keys %INC) {
        next unless $loaded =~ /\.pm$/;

        my $mod = $loaded;
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};

        my $fh = do {
            no strict 'refs';
            no warnings 'once';
            *{$mod . '::DATA'};
        };

        next unless openhandle($fh);
        push @$list => [$mod, $INC{$loaded}, tell($fh)];
    }

    return $list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::Job::Runner::Fork - Logic for running a test job by forking.

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
