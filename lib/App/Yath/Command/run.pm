package App::Yath::Command::run;
use strict;
use warnings;

our $VERSION = '1.000077';

use App::Yath::Options;

use Test2::Harness::Run;
use Test2::Harness::Util::Queue;
use Test2::Harness::Util::File::JSON;
use Test2::Harness::IPC;

use App::Yath::Util qw/find_pfile/;
use Test2::Harness::Util qw/open_file/;
use Test2::Harness::Util qw/mod2file open_file/;
use Test2::Util::Table qw/table/;

use File::Spec;

use Carp qw/croak/;

use parent 'App::Yath::Command::test';
use Test2::Harness::Util::HashBase qw/+pfile_data +pfile/;

include_options(
    'App::Yath::Options::Debug',
    'App::Yath::Options::Display',
    'App::Yath::Options::Finder',
    'App::Yath::Options::Logging',
    'App::Yath::Options::PreCommand',
    'App::Yath::Options::Run',
);

sub group { 'persist' }

sub summary { "Run tests using the persistent test runner" }
sub cli_args { "[--] [test files/dirs] [::] [arguments to test scripts]" }

sub description {
    return <<"    EOT";
This command will run tests through an already started persistent instance. See
the start command for details on how to launch a persistant instance.
    EOT
}

sub terminate_queue {}
sub write_settings_to {}
sub setup_plugins {}
sub teardown_plugins {}
sub finalize_plugins {}

sub monitor_preloads { 1 }
sub job_count { 1 }

sub pfile {
    my $self = shift;
    $self->{+PFILE} //= find_pfile($self->settings) or die "No persistent harness was found for the current path.\n";
}

sub pfile_data {
    my $self = shift;
    return $self->{+PFILE_DATA} if $self->{+PFILE_DATA};

    my $pfile = $self->pfile;

    return $self->{+PFILE_DATA} = Test2::Harness::Util::File::JSON->new(name => $pfile)->read();
}

sub workdir {
    my $self = shift;
    return $self->pfile_data->{dir};
}

sub start_runner {
    my $self = shift;

    my $data = $self->pfile_data;

    if ($data->{version} ne $VERSION) {
        die "Version mismatch, persistent runner is version $data->{version}, runner is version $VERSION.\n";
    }

    $self->{+RUNNER_PID} = $data->{pid};
}

1;

__END__

=head1 POD IS AUTO-GENERATED

