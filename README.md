# recurseFtp
retrieve or list files from an FTP site recursively in an automated fashion

##Installation

This script requires the following non-core perl modules:
 
 *  Net::FTP::AutoReconnect
 *  Net::FTP::File
 *  Term::ReadPassword
 *  Term::Size::Perl 

Install these via cpan. For example: 

 cpan -i Net::FTP::AutoReconnect Net::FTP::File Getopt::Long Term::ReadPassword 

Clone the repository to create the recurseFtp folder.

 git clone https://github.com/gantzgraf/recurseFtp.git

cd into the newly downloaded folder and run the script for usage information

 ./recurseFtp.pl --help

##Usage

 ./recurseFtp.pl [options]
 ./recurseFtp.pl -f [ftp address] -u [username] [options]
 ./recurseFtp.pl -h (display help message)
 ./recurseFtp.pl -M (display manual page)

##AUTHOR

David A. Parry

##COPYRIGHT AND LICENSE

Copyright 2011 David A. Parry

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

=
