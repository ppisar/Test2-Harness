package Test2::Harness::LogFormat;
use strict;
use warnings;

our $VERSION = '0.001088';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::LogFormat

=head1 DESCRIPTION

This module describes the yath log format in detail.

=head1 OVERVIEW

The log file is a JSONL file. This means that each line is a complete JSON
document. Any given line in the log may be parsed by a JSON parser
independently of any other line.

Each line in the log is exactly 1 event as seen or produced by the harness.

Events in the log should be in the order they were seen by the harness, no
sorting or re-ordering should be done.

When tests were run concurrently it is perfectly valid for events from multiple
test jobs to be muxed together; in other words events are not grouped by test.

=head1 EVENT FORMAT

Events may have the following fields at the top level, some fields are
optional:

=over 4

=item assert_count

The total number of assertions made up to and including this event in the
current subtest or top level test if this event is not inside a subtest.

This may be null, or a whole integer greater than or equal to 0.

This field is optional and does not appear in harness generated events, only in
events passed through from tests.

=item event_id

This field is B<required>.

This field should be an ID for the event, and should be a UUID. Be aware some
logs may have a string that is not a UUID if a UUID library was unavailable.
For safety assume it is a unique string, but do not assume it is a UUID.

Tools may assume this field is always a UUID and refuse to process logs that do
not use UUIDS. Please document such when the tools are written.

=item facet_data

See the L</"FACET DATA"> section.

This field is B<required>, and some fields within it are also B<required>.

=item job_id

This should be the unique ID of the job to which the event belongs. The harness
itself will set this field to C<0> for any events generated by the harness
itself.

This field is normally C<0> for the harness, and a UUID for a real test job. In
some cases this may be a unique string that is not a UUID, but tools are free
to refuse to process logs that do not use UUIDs here. Note that even when UUIDs
are used the harness itself will set the field to C<0> for internal harness
events.

=item pid

The process ID from which the event was generated.

This field is B<optional>. Most test events should include this field, harness
internal events will usually omit it.

=item run_id

The run identification. All events must have the same run_id. This field is a
unique string, usually a UUID. Tools are free to reject logs that do not use a
UUID for this field.

=item stamp

The timestamp for when the event was seen by the harness. This field is
B<required>.

B<Note> The stamp is I<usually> the stamp for when the event was generated, but
in some cases it may be more accurately described as when the harness first saw
the event. This is because the harness sets the field if it is missing, but in
most cases the test itself set the field first at event creation.

=item stream_id

This field is B<optional>. This field is set by the test and is used to
synchronize events, stdout and stderr.

It is safest to never tamper with, or backfill this field. If you are trying to
write a tool that outputs the yath log format from another source it is best to
omit this field completely.

=item tid

The thread ID from which the event was generated.

This field is B<optional>. Most test events should include this field, harness
internal events will usually omit it.

=item times

This field is B<optional>. This field includes timing data from the process at
the time the event was generated.

   "times" : [
      0.04,     # user
      0.01,     # system
      0,        # cuser
      0         # csystem
   ]

The data inside the array is the result of the C<times()> function as
documented at L<https://perldoc.perl.org/5.30.0/functions/times.html>.

This field will only be present when L<Test2::Formatter::Stream> was used. TAP
and other formats do not generate this field.

=back

=head1 FACET DATA

Facets are what convey useful information about test state from test to
harness. In addition some facets are added by the harness itself to convey
information for anything that reads the log.

C<"facet_data"> is a hash, each field is the name of a facet. All facets are
hashes, but some facet types allow multiple hashes to be specified in which
case the field has a list of them. Each facet type is documented, including the
type it wants, hash vs list of hashes.

There are 3 categories of facet:

=head2 HARNESS FACETS

=head3 harness

This facet is always a single hash containing a duplicate of some top-level data:

    "harness" : {
       "event_id" : "A07FDDFC-9C37-11E9-AE8C-DFDAB0029DDD",
       "job_id" : "A06685B4-9C37-11E9-88CA-DEDAB0029DDD",
       "run_id" : "A0649E8E-9C37-11E9-88CA-DEDAB0029DDD"
    }

This facet is B<required>. Many tools choose to ignore any data outside of
facet_data, so it is important to list these values here.

=head3 harness_run

This facet contains the details of the test run, which includes environment
variables set, where test files were found, library directories that were in
use, and flags passed to yath when it was executed.

Example:

    "harness_run" : {
       "args" : [],
       "blib" : 1,
       "cover" : null,
       "default_search" : [
          "./t",
          "./t2",
          "test.pl"
       ],
       "dummy" : 0,
       "env_vars" : {
          "HARNESS_ACTIVE" : 1,
          "HARNESS_IS_VERBOSE" : 0,
          "HARNESS_JOBS" : 1,
          "HARNESS_VERSION" : "Test2-Harness-0.001078",
          "PERL_USE_UNSAFE_INC" : 1,
          "T2_HARNESS_ACTIVE" : 1,
          "T2_HARNESS_IS_VERBOSE" : 0,
          "T2_HARNESS_JOBS" : 1,
          "T2_HARNESS_RUN_ID" : "A0649E8E-9C37-11E9-88CA-DEDAB0029DDD",
          "T2_HARNESS_VERSION" : "0.001078"
       },
       "event_uuids" : 1,
       "exclude_files" : {},
       "exclude_patterns" : [],
       "finite" : 1,
       "input" : null,
       "job_count" : 1,
       "lib" : 1,
       "libs" : [
          "/lib",
          "/blib/lib",
          "/blib/arch"
       ],
       "load" : null,
       "load_import" : null,
       "mem_usage" : 1,
       "no_long" : null,
       "plugins" : [],
       "preload" : null,
       "run_id" : "A0649E8E-9C37-11E9-88CA-DEDAB0029DDD",
       "search" : [
          "tiny.t"
       ],
       "show_times" : null,
       "switches" : [],
       "times" : 1,
       "tlib" : 0,
       "unsafe_inc" : 1,
       "use_fork" : 1,
       "use_stream" : 1,
       "verbose" : 0
    }

=head3 harness_job

This facet is almost always paired with the L</"harness_job_launch"> facet.
This facet is always a single hash which describes the test job that is
starting. This facet will show up in the log once per test file executed.

example from the start of C<tiny.t>:

    "harness_job" : {
       "args" : [],
       "category" : "general",
       "conflicts" : [],
       "env_vars" : {
          "HARNESS_ACTIVE" : 1,
          "HARNESS_IS_VERBOSE" : 0,
          "HARNESS_JOBS" : 1,
          "HARNESS_VERSION" : "Test2-Harness-0.001078",
          "PERL5LIB" : "/lib:/blib/lib:/blib/arch",
          "PERL_USE_UNSAFE_INC" : null,
          "T2_HARNESS_ACTIVE" : 1,
          "T2_HARNESS_IS_VERBOSE" : 0,
          "T2_HARNESS_JOBS" : 1,
          "T2_HARNESS_RUN_ID" : "A0649E8E-9C37-11E9-88CA-DEDAB0029DDD",
          "T2_HARNESS_VERSION" : "0.001078",
          "TEMPDIR" : "/tmp/yath-test-28710-kFqwxNKE/A06685B4-9C37-11E9-88CA-DEDAB0029DDD/tmp",
          "TEST2_JOB_DIR" : "/tmp/yath-test-28710-kFqwxNKE/A06685B4-9C37-11E9-88CA-DEDAB0029DDD",
          "TMPDIR" : "/tmp/yath-test-28710-kFqwxNKE/A06685B4-9C37-11E9-88CA-DEDAB0029DDD/tmp"
       },
       "event_timeout" : null,
       "event_uuids" : 1,
       "file" : "/tiny.t",
       "headers" : {},
       "input" : "",
       "job_id" : "A06685B4-9C37-11E9-88CA-DEDAB0029DDD",
       "job_name" : 1,
       "libs" : [
          "/lib",
          "/blib/lib",
          "/blib/arch"
       ],
       "load" : [],
       "load_import" : [],
       "mem_usage" : 1,
       "pid" : 28712,
       "postexit_timeout" : null,
       "preload" : [],
       "shbang" : {},
       "show_times" : null,
       "stage" : "default",
       "stamp" : 1562009833.97186,
       "switches" : [],
       "times" : 1,
       "use_fork" : 1,
       "use_preload" : 1,
       "use_stream" : 1,
       "use_timeout" : 1
    },

=head3 harness_job_launch

This facet is present when the harness launches a new job, it is usually paired
with the C<harness_job> facet. The main point of this facet is to provide a
timestamp for job start before the test itself can generate any events.

    "harness_job_launch" : {
       "retry" : null,
       "stamp" : 1562009834.09536
    }

=head3 harness_job_start

This facet is generated when the test process actually starts (vs when the
harness asks it to via launch). This is often generated in a process other than
the main harness process, so can be used to see how long it takes for the test
process to spawn.

    "harness_job_start" : {
       "details" : "Job A06685B4-9C37-11E9-88CA-DEDAB0029DDD started at 1562009834.08625",
       "file" : "/tiny.t",
       "job_id" : "A06685B4-9C37-11E9-88CA-DEDAB0029DDD",
       "stamp" : "1562009834.08625"
    }

=head3 harness_job_exit

This facet is generated when the test process has exited. This facet will
contain the exit code as well as a complete and unfiltered version of the
STDOUT and STDERR output. If L<Test2::Formatter::Stream> was used then this
will include the T2-HARNESS-ESYNC codes used to make sure STDOUT, STDERR, and
all events line up properly.

      "harness_job_exit" : {
         "details" : "Test script exited 256",
         "exit" : "256",
         "file" : "/tiny.t",
         "job_id" : "A06685B4-9C37-11E9-88CA-DEDAB0029DDD",
         "stderr" : "...",
         "stdout" : "...",
      }

=head3 harness_job_end

This facet is generated when the harness is closing off the test after the test
process has exited.

    "harness_job_end" : {
       "fail" : 1,
       "file" : "/tiny.t",
       "stamp" : 1562009834.15989
    }

=head2 TEST FACETS

Test facets are documented at L<Test2::Manual::Anatomy::Event/"THE-FACET-API">.

=head3 passing assertion example

B<Note> In the proper log this would all be on one line.

    "facet_data" : {
       "about" : {
          "eid" : "28712~0~1562009834~4",
          "package" : "Test2::Event::Pass",
          "uuid" : "A07FE270-9C37-11E9-AE8C-DFDAB0029DDD"
       },
       "assert" : {
          "details" : "A passing test",
          "pass" : 1
       },
       "control" : {},
       "harness" : {
          "event_id" : "A07FE270-9C37-11E9-AE8C-DFDAB0029DDD",
          "job_id" : "A06685B4-9C37-11E9-88CA-DEDAB0029DDD",
          "run_id" : "A0649E8E-9C37-11E9-88CA-DEDAB0029DDD"
       },
       "hubs" : [
          {
             "buffered" : 0,
             "details" : "Test2::Hub",
             "hid" : "28712~0~1562009834~2",
             "ipc" : 0,
             "nested" : 0,
             "pid" : 28712,
             "tid" : 0,
             "uuid" : "A07FD85C-9C37-11E9-AE8C-DFDAB0029DDD"
          }
       ],
       "trace" : {
          "buffered" : 0,
          "cid" : "28712~0~1562009834~3",
          "frame" : [
             "main",
             "tiny.t",
             3,
             "main::ok"
          ],
          "hid" : "28712~0~1562009834~2",
          "huuid" : "A07FD85C-9C37-11E9-AE8C-DFDAB0029DDD",
          "nested" : 0,
          "pid" : 28712,
          "tid" : 0,
          "uuid" : "A07FE108-9C37-11E9-AE8C-DFDAB0029DDD"
       }
    },

=head3 failing assertion example

    "facet_data" : {
       "about" : {
          "details" : "fail",
          "eid" : "3287~0~1562020001~4",
          "package" : "Test2::Event::Fail",
          "uuid" : "4C6EF67C-9C4F-11E9-80B8-8E77B0029DDD"
       },
       "assert" : {
          "details" : "a failing test",
          "pass" : 0
       },
       "control" : {},
       "harness" : {
          "event_id" : "4C6EF67C-9C4F-11E9-80B8-8E77B0029DDD",
          "job_id" : "4C5570F8-9C4F-11E9-B087-8D77B0029DDD",
          "run_id" : "4C538A2C-9C4F-11E9-B087-8D77B0029DDD"
       },
       "hubs" : [
          {
             "buffered" : 0,
             "details" : "Test2::Hub",
             "hid" : "3287~0~1562020001~2",
             "ipc" : 0,
             "nested" : 0,
             "pid" : 3287,
             "tid" : 0,
             "uuid" : "4C6EEB96-9C4F-11E9-80B8-8E77B0029DDD"
          }
       ],
       "info" : [
          {
             "debug" : 1,
             "details" : "This is a diagnostics message for the fail",
             "tag" : "DIAG"
          },
          {
             "debug" : 1,
             "details" : "Another diagnostics message",
             "tag" : "DIAG"
          }
       ],
       "trace" : {
          "buffered" : 0,
          "cid" : "3287~0~1562020001~3",
          "frame" : [
             "main",
             "tiny.t",
             11,
             "main::ok"
          ],
          "hid" : "3287~0~1562020001~2",
          "huuid" : "4C6EEB96-9C4F-11E9-80B8-8E77B0029DDD",
          "nested" : 0,
          "pid" : 3287,
          "tid" : 0,
          "uuid" : "4C6EF47E-9C4F-11E9-80B8-8E77B0029DDD"
       }
    },

=head2 OTHER FACETS

Other facets are any facet not defined above. These facets may come from any
number of plugins or tools. The rule is to ignore and pass-through any facet
your tool does not know how to handle.

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

Copyright 2019 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

