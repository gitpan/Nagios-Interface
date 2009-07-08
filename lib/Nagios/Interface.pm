
package Nagios::Interface;

use Class::AutoUse
	qw(Nagios::Interface::Logfile Nagios::Interface::Status
	   Nagios::Interface::Control);

sub default_author {
	$ENV{LOGNAME}||$ENV{USER}||(getpwuid($<))[0]
}

our $VERSION = "0.01";

1;

__END__

=head1 NAME

Nagios::Interface - Run-time interaction with Nagios

=head1 SYNOPSIS

 use Nagios::Interface;

 # set up a logfile reader which uses File::Tail
 my $logfile = Nagios::Interface::Logfile->new(
         tail => File::Tail->new(
                 name => "/var/log/nagios3/nagios.log",
                 maxinterval => 5,
                 interval => 2,
                 tail => 10,
                 ),
         );

 # read a message, parse it and return it
 my $log_message = $logfile->get_message;

 # or if you get loglines from somewhere else, pass to parse_logline
 $log_message = $logfile->parse_logline($_);

 # returned messages have roles for commonality and classes for type.
 print $log_message->host . " is " .
      ($log_message->up ? "UP" : "DOWN");
    if $log_message->does("Nagios::Interface::Alert::Host");

 # controlling via the nagios control file
 my $control = Nagios::Interface::Control->new(
         filename => "/var/lib/nagios3/rw/nagios.cmd",
         );

 # make any kind of log message to issue as a command...
 # see Nagios::Interface::ConcreteTypes for a list
 my $svc_downtime = Nagios::Interface::ScheduleServiceDowntime->new(
         begin => time,
         end   => time + 15 * 60,
         fixed => 1,
         author => ($ENV{LOGNAME}||$ENV{USER}||(getpwuid($<))[0]),
         comment => "here's a comment",
         );
 my $entry_time = $control->issue($svc_downtime);

 # reading the status log
 my $status = Nagios::Interface::Status->new(
         filename => "/var/cache/nagios3/status.dat",
         );

 sleep 1 while ( (stat $status->filename)[9] < $issue_time );
 $status->parse_file;

 my @blocks = grep {
                 $_->{entry_time} == $entry_time &&
                         $_->{comment} eq "here's a comment",
         } $status->get_blocks("servicedowntime");

 use Set::Object qw(set);
 my $downtime_ids = set( map { $_->{downtime_id} } @blocks) );
 print "Downtime IDs: $downtime_ids\n";

 # now cancel the downtime, to complete the example
 $control->issue(
         map {
                 Nagios::Interface::DeleteServiceDowntime->new(
                         downtime_id => $_
                 )
         } $downtime_ids->members
         );

=head1 DESCRIPTION

B<Nagios::Interface> is currently a fledgling module for basic run-time
interaction with Nagios 3 instances.  There are no functions to parse
or write configuration files (yet?), but it can parse most logfile
messages, as well as write control messages and parse the status file
for receipts of actions that did not log anything useful.

The main entry points of the modules are:

=over

=item *

L<Nagios::Interface::Logfile> - for parsing the nagios log file

=item *

L<Nagios::Interface::Status> - for parsing the nagios status file

=item *

L<Nagios::Interface::Control> - issuing commands to nagios

=item *

L<Nagios::Interface::ConcreteTypes> - type registry of nagios messages, alerts, events, etc

=back

=head1 AUTHOR AND LICENSE

Written by Sam Vilain, <samv@cpan.org>.

Some development work sponsored by Catalyst IT
L<http://www.catalyst.net.nz>, and the rest by NZ Registry Services
L<http://www.nzrs.net.nz>.

Copyright (c) 2008, 2009.  All Rights Reserved.  This program is free
software; you may use it and/or distribute it under the same terms as
Perl itself, or the terms of the GPL version 3 or later.

=head1 CONTRIBUTING CHANGES

Changes are most welcome.  The source of the module is published at
L<http://github.com/samv/MooseX-Nagios> - please submit a pull
request.

=cut

