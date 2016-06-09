#!/usr/bin/env perl
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use File::Path qw(make_path);
use Cwd;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/lib";
use RecurseFTP;
my $site;    #address
my $username;
my $dir;     #place to put files if not pwd
my @remote_dir= ();
my $regex;
my $no_password;
my $help;
my $man;
my $skip_existing;
my $warn_overwrite;
my $replace_smaller;
my $list_only;
my $retries = 0;
GetOptions(
    "f|ftp=s"                   => \$site,
    "l|list_files"              => \$list_only,
    "n|no_password"             => \$no_password,
    "u|username=s"              => \$username,
    "d|directory=s"             => \$dir,
    "r|remote_directory=s{,}"   => \@remote_dir,
    "m|match=s"                 => \$regex,
    "s|skip_existing"           => \$skip_existing,
    "w|warn_before_overwriting" => \$warn_overwrite,
    "b|bigger"                  => \$replace_smaller,
    "a|attempts=i"              => \$retries,
    "h|?|help"                  => \$help,
    "M|manual"                  => \$man
) or pod2usage( -message => "Syntax error", -exitval => 2 );
pod2usage( -verbose => 2 ) if $man;
pod2usage( -verbose => 1 ) if $help;

if ($dir) {
    if ( not -d $dir ) {
        print STDERR
          "Local directory $dir does not exist - attempting to create it... ";
        make_path $dir || die "Can't make directory $dir: $!\n";
        print STDERR "Done\n";
    }
    chdir $dir || die "Can't enter local directory $dir: $!\n";
}
my $local_root_dir = getcwd();
if ( not $site ) {
    print STDERR
      "Please enter the address of the ftp site you wish to connect to: ";
    chomp( $site = (<STDIN>) );
}
if ( not defined $username ) {
    print STDERR "Please enter your username for $site: ";
    chomp( $username = (<STDIN>) );

}
print STDERR "Attempting to connect to $site...\n";
my $ftp;
if ($username) {
    $ftp = RecurseFTP->new( site => $site, username => $username, );
}
else {
    $ftp = RecurseFTP->new( site => $site, );
}
if ($no_password) {
    $ftp->set_no_password(1);
}
$ftp->login();
$ftp->set_mode("binary");
if ($regex) {
    print STDERR "Getting files mathing $regex...\n";
    $ftp->set_file_match($regex);
}

if ($warn_overwrite) {
    $ftp->set_warn_before_overwriting(1);
}
if ($skip_existing) {
    $ftp->set_skip_existing(1);
}
if ($replace_smaller) {
    $ftp->set_overwrite_smaller(1);
}
if ($retries) {
    $ftp->set_retries($retries);
}
if (@remote_dir) {
    foreach my $remote (@remote_dir){
        $remote =~ s/^[\/\\]//;
        $ftp->set_dir($remote);
        if ($list_only) {
            print STDERR "Listing files in $remote...\n";
            my @list = $ftp->read_files_recursively();
            print join( "\n", @list ) . "\n";
        }
        else {
            print STDERR "Getting files from $remote...\n";
            $ftp->get_files_recursively();
        }
    }
}
print STDERR "Done!\n";
$ftp->quit;

=head1 NAME

recurseFtp.pl - recursively retrieve files from an ftp site automatically.

=head1 SYNOPSIS

    recurseFtp.pl [options]
    recurseFtp.pl -f [ftp address] -u [username] [options]
    recurseFtp.pl -h (display help message)
    recurseFtp.pl -M (display manual page)

=cut

=head1 ARGUMENTS

=over 8

=item B<-f    --ftp>

Address of ftp site.

=item B<-u    --username>

Username for ftp site.

=item B<-d    --directory>

Local directory to put files (default is current directory).

=item B<-r    --remote_directory>

One or more remote directories to start copying files from.

=item B<-m    --match>

A string or pattern files must match in order to be retrieved.

=item B<-s    --skip_existing>

Use this flag to skip downloading of files that already exist on local machine.

=item B<-w    --warn_before_overwriting>

Use this flag to warn before overwriting an existing file and give the option to skip.

=item B<-b    --bigger>

Use this flag to only overwrite local files if the remote file is larger. Useful for resuming aborted downloads. This option will be ignored if either --skip_existing or --warn_before_overwriting flags are in use.

=item B<-a    --attempts>

Number of retries per file if a transfer fails. Failure is defined as the local file being smaller than the remote file after a transfer attempt. 

=item B<-l    --list_files>

Use this flag to list rather than retrieve files from the FTP site. You may find it useful to use this option to perform a 'dry run' in order to check your settings before downloading.

=item B<-n    --no_password>

Use this flag if the ftp site does not require a password. This will skip the password prompt normally required before log in.

=item B<-h    --help>

Display help message.

=item B<-M    --manual>

Display manual page.

=back 

=cut

=head1 DESCRIPTION

This program allows you to log in to an ftp site using and retrieve files recursively or read the contents of an ftp site recursively. You can set the directory to start retrieving files recursively from and also set regular expressions to only retrieve the contents that match.

=head1 AUTHOR

David A. Parry

=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2012  David A. Parry

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
