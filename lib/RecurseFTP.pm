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




=head1 NAME

RecurseFTP - recursively search or retrieve files from and FTP site.

=head1 SYNOPSIS

  use RecurseFTP;

  my $recurse = RecurseFTP->new(site=>"111.111.1.111");

  $recurse -> login(username => "username");

  $recurse -> set_dir("remote_directory");

  $recurse -> set_file_match('^rege[xy]$');

  $recurse->get_files_recursively();

  my @files = $recurse->read_files_recursively();


=head1 DESCRIPTION


=head2 Overview

This module allows you to log in to an ftp site using Net::FTP and retrieve files recursively or read the contents of an ftp site recursively. It does not check permissions or have other sophisticated functions like Net::FTP::Recursive but unlike Net::FTP::Recursive it does work on Windows servers as well as Linux servers. You can set the directory to start retrieving files recursively from and also set regular expressions to only retrieve the contents that match. 

=head2 Constructor and initialization

An object may be created using the 'new' method specifying, at a minimum, the address of the ftp site. 

  my $recurse = RecurseFTP->new(site => "111.111.1.111");

You may wish to set the username, directory, retrieval mode and file and/or directory match pattern at the same time:

  my $recurse = RecurseFTP->new
  (
      site       => "111.111.1.111", 
      username   => "username", 
      dir        => "/some/remote_dir", 
      mode       => 'binary', 
      file_match => '^rege[xy]$',
  );


=head2 Class and object methods


=head3 Accessors and mutators

The following features can be accessed using get_[feature] or set using set_[feature], substituting [feature] for the feature of interest. 

=over 12

=item B<username>

Username for logging into the ftp site. Default is "anonymous".

=item B<no_password>

If true then you will not be prompted for a password on login.

=item B<dir>

Remote directory to start retrieving/reading files from. 

=item B<mode>

Retrieval mode to use - see Net::FTP for valid values.

=item B<file_match>

Specify a pattern that files must match before reading or retrieving.  Remember to use single quotes (') if using regular expressions.

=item B<dir_match>

As above but for directories. Directories will only be read and files retrieved if the directory matches this pattern.

=item B<local_dir>

Location of local directory to retrieve files to. Will be created if it doesn't exist. 

=item B<site>

Address of the site to connect to.

=item B<skip_existing>

If true then existing files on the local machine will not be overwritten.

=item B<warn_before_overwriting>

If true then will wait for confirmation before overwriting files on the local machine.

=item B<overwrite_smaller>

If true and warn_before_overwriting and skip_existing values are false then local files will only be  overwritten if the local copy is smaller than that on the remote machine.

=item B<retries>

Number of times to reattempt a transfer if retrieval fails.  Uses the size of the file on the remote server to test whether a file has been retrieved successfully. Defaults to 0.

=back

=head3 Methods

=over 12

=item B<login>

Login to ftp site.  Before retrieving files you must log in.  This method will prompt you for a password unless 'no_password' option is set. You may set 'dir', 'username', 'mode' or 'site' arguments here.

    $recurse -> login();
    $recurse -> login(username => "username");

=item B<read_files_recursively>

Return an array containing all the files and directories in the ftp site in your specified remote directory (if any) and contained folders. You may set 'dir', 'file_match' and 'dir_match' arguments when calling this method. 

    my @file_list = $recurse -> read_files_recursively();
    my @file_list = $recurse -> read_files_recursively
    (
        dir         =>"/some/remote_directory/", 
        file_match  =>'^rege[xy]$', 
        dir_match   =>'another_pattern$',
    );

=item B<get_files_recursively>

Retrieve files and folders recursively.  Items will be copied to your present working directory unless the 'local_dir' option is specified, in which case files will be downloaded to the directory specified. You may set 'local_dir', 'dir', 'file_match' and 'dir_match' arguments when calling this method.

    $recurse -> get_files_recursively();
    $recurse -> get_files_recursively
    (
        local_dir  => "/home/me/Documents", 
        dir        => "/some/remote_directory/", 
        file_match => '^rege[xy]$', 
        dir_match  => 'another_pattern$',
    );

=back

=head1 AUTHOR

David A. Parry
University of Leeds


=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2012  David A. Parry

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut



package RecurseFTP;
use strict;
use warnings;

#use Net::FTP;
use Net::FTP::AutoReconnect;
use Net::FTP::File;
use Getopt::Long;
use Term::ReadPassword;
use Term::Size::Perl qw(chars);
use File::Path qw(make_path);
use Cwd;
use Pod::Usage;
use Carp;
use Time::HiRes qw(usleep);
our $VERSION = 0.1; 
our $AUTOLOAD;
{
    my $_count = 0;
    my %_attrs = (
    _site => ["", "read/write/required"],
    _dir => ["", "read/write"],
    _local_dir => ["", "read/write"],
    _username => ["anonymous", "read/write"],
    _file_match => ["", "read/write"],
    _dir_match => ["", "read/write"],
    _mode => ["", "read/write"],
    _no_password => [0, "read/write"],
    _skip_existing => [0, "read/write"],
    _warn_before_overwriting => [0, "read/write"],
    _overwrite_smaller => [0, "read/write"],
    _retries  => [0, "read/write"],
    );
    sub _all_attrs{
        keys %_attrs;
    }
    sub _accessible{
        my ($self, $attr, $mode) = @_;
        $_attrs{$attr}[1] =~ /$mode/
    }
    sub _attr_default{
        my ($self, $attr) = @_;
        $_attrs{$attr}[0];
    }
    sub get_count{
        $_count;
    }
    sub _incr_count{
        $_count++;
    }
    sub _decr_count{
        $_count--;
    }

}

sub DESTROY{
    my ($self) = @_;
    if ($self->{_ftp_object}){
        $self->{_ftp_object}->quit();
    }
    $self -> _decr_count( );
}

sub quit{
    my ($self) = @_;
    if ($self->{_ftp_object}){
        $self->{_ftp_object}->quit();    
    }
}
sub new {
    my ($class, %args) = @_;
    my $self = bless { }, $class;
    foreach my $attr ($self -> _all_attrs( ) ){
        my ($arg) = ($attr =~ /^_(.*)/);
        if (exists $args{$arg}){
            $self->{$attr} = $args{$arg};
        }elsif($self->_accessible($attr, "required")){
            croak "$attr argument required";
        }else{
            $self->{$attr} = $self->_attr_default($attr);
        }
    }
    $class -> _incr_count();
    return $self;
}

sub set_mode{
    my ($self, $val) = @_;
    if (not $self->{_ftp_object}){
        carp "Can't set mode before login - set_mode failed! ";
    }else{
        $self->{_ftp_object} -> $val();
    }
}
    
    

#use autoload for standard ->get and ->set methods
sub AUTOLOAD{
    my ($self, $val) = @_;
    no strict 'refs';
    if ($AUTOLOAD =~ /.*::get(_\w+)/ and $self -> _accessible($1, "read")){
        my $attr = $1;
        croak "No such attribute \"$attr\"" unless exists $self->{$attr};
        *{$AUTOLOAD} = sub { return $_[0] -> {$attr} };
        return $self->{$attr};
    }elsif ($AUTOLOAD =~ /.*::set(_\w+)/ and $self -> _accessible($1, "write")){
        my $attr = $1;
        croak "No such attribute \"$attr\"" unless exists $self->{$attr};
        #$self -> _strip_chr() if $attr eq "chrom";
        *{$AUTOLOAD} = sub { $_[0] -> {$attr} = $_[1]; return ; };
        $self -> {$attr} = $val;
        return
    }else{
        croak "Method name \"$AUTOLOAD\" not available";
    }
}

##############################
sub login{
    my ($self, %args) = @_;
    
    set_dir($self, $args{dir}) if ($args{dir});    
    set_username($self, $args{username}) if ($args{username});    
    set_site($self, $args{site}) if ($args{site});    
    $self->{_mode} = $args{mode} if ($args{mode});    
    
    my $ftp = Net::FTP->new($self->{_site});
    
    croak "FTP object could not be created - please check the address of the ".
          "ftp site you provided " if not defined $ftp;
    my $password = "";
    $password = read_password
    (
        "Enter password for $self->{_username}: "
    ) unless $self->{_no_password};
    
    $ftp -> login
    (
        $self->{_username}, 
        $password,
    )or croak "\nCould not login to $self->{_site} with user credentials. ", 
              $ftp->message;
    
    $self->{_ftp_object} =  $ftp;
    
    set_mode($self, $self->{_mode}) if ($self->{_mode});
}

##############################
sub read_files_recursively{
    my ($self, %args) = @_;
    set_file_match
    (
        $self, 
        $args{_file_match}
    ) if ($args{_file_match});
    
    set_dir_match
    (
        $self, 
        $args{_dir_match}
    ) if ($args{_dir_match});
    
    set_dir
    (
        $self, 
        $args{dir}
    ) if ($args{dir});    
    
    my $cwd = getcwd();
    my @list = read_files_traverse_directories
    (
        $self, 
        $self->{_ftp_object}, 
        $self->{_dir},
    );
    return @list if defined(wantarray);
    carp "read_files_recursively method called in void context ";
}

##############################
sub read_files_traverse_directories{
    my ($self, $ftp, $remote_dir, $dir_cat) = @_;
    my $remote_root = $ftp->pwd();
    if ($remote_dir){
        print STDERR "Processing directory $remote_dir...\n";
        $ftp->cwd($remote_dir) 
           or croak "Can't enter remote directory $remote_dir " , $ftp->message;
    }
    my @list = $ftp->ls();
    my @dirs = ();
    my @files = ();
LIST: foreach my $l (@list){
        if ($ftp->isfile($l)){
        #implement _file_match here
            if ($self->{_file_match}){
                if ($l !~ m/$self->{_file_match}/){
                    next LIST;
                }
            }
            $l = "$dir_cat/$l" if ($dir_cat);
            push (@files, $l);
        }elsif ($ftp->isdir($l)){
            push (@dirs, $l);
        }
    }
DIR: foreach my $dir (@dirs){
        my $cwd = getcwd();
        #implement _dir_match here
        if ($self->{_dir_match}){
            if ($dir !~ m/$self->{_dir_match}/){
                next DIR;
            }
        }
        my $dir_cat_temp = $dir;
        if ($dir_cat){
            $dir_cat_temp = "$dir_cat/$dir";
        }
        push(@files, $dir_cat_temp);
        push (@files,  read_files_traverse_directories($self, $ftp, $dir, $dir_cat_temp));
    }
    $ftp -> cwd($remote_root) 
        or croak "Can't move back to remote directory $remote_root ", 
        $ftp->message;
    return @files if defined(wantarray);
    carp "read_files_traverse_directories called in void context";
}

##############################
sub get_files_recursively{
    my ($self, %args) = @_;
    set_local_dir
    (
        $self, 
        $args{local_dir},
    ) if ($args{local_dir});
    
    set_file_match
    (
        $self, 
        $args{_file_match}
    ) if ($args{_file_match});
    
    set_dir_match
    (
        $self, 
        $args{_dir_match}
    ) if ($args{_dir_match});
    
    set_dir(
        $self, 
        $args{dir}
    ) if ($args{dir});    
    
    my $cwd = getcwd();
    set_local_dir
    (
        $self, 
        $cwd
    ) if (not $self->{local_dir});    
    
    get_files_traverse_directories
    (
        $self, 
        $self->{_ftp_object}, 
        $self->{_local_dir}, 
        $self->{_dir}
    );
}

##############################
sub get_files_traverse_directories{
    my ($self, $ftp, $root, $remote_dir) = @_;
    my $pwd = getcwd();
    $root =~ s/\/$//;
    my $rootquote = quotemeta($root);
    if ($pwd !~ /$rootquote$/){
         chdir $rootquote || croak "$! ";
    }
    my $remote_root = $ftp->pwd();
    if ($remote_dir){
        print STDERR "Processing directory $remote_dir...\n";
        $ftp->cwd($remote_dir) 
           or croak "Can't enter remote directory $remote_dir " , $ftp->message;
        if (not -d $remote_dir){
            make_path($remote_dir) 
                or croak "Can't make matching directory $remote_dir: $!\n";
        }
        chdir $remote_dir 
            or croak "Can't enter local directorey $remote_dir: $!\n";
    }
    my @list = $ftp->ls();
    my @dirs = ();
LIST: foreach my $l (@list){
        if ($ftp->isfile($l)){
        #implement _file_match here
            if ($self->{_file_match}){
                if ($l !~ m/$self->{_file_match}/){
                    next LIST;
                }
            }
            my $file_size = $ftp->size($l);
            if ($self->{_skip_existing}){
                next LIST if (-e $l);#check if local file exists
            }
            if ($self->{_warn_before_overwriting}){
                if (-e $l){#check if local file exists
                    my $local_size = -s $l;
                    print STDERR "Warning - local file $l already exists.\n";
                    print STDERR "Local file is $local_size size bytes, remote".
                                " file is $file_size bytes. Overwrite? (y/n)\n";
                    while (my $answer = <STDIN>){  
                        chomp $answer; 
                        if ($answer =~ /^y/i){
                            last;
                        }elsif ($answer =~ /^n/i){
                            print STDERR "Skipping...\n";
                            next LIST;
                        }else{
                            print STDERR "Please answer either \"y\" or \"n\"\n";
                        }
                    }
                }
            }elsif ($self->{_overwrite_smaller}){
                if (-e $l){#check if local file exists
                    my $local_size = -s $l;
                    if ($local_size >= $file_size){
                        print STDERR "Skipping $l (local file size $local_size".
                                     ", remote file size $file_size)\n";
                        next LIST; 
                    }else{
                        print STDERR "Replacing $l (local file size $local_size"
                                     .", remote file size $file_size)\n";
                    }
                }
            }
            if ($file_size){
                #print STDERR "Getting file $l... ($file_size bytes)\n";
                my ($sensible_size, $sensible_units) 
                    = get_sensible_units($file_size);
                printf STDERR 
                (
                    "Getting file $l... (%.2f $sensible_units)\n", 
                    $sensible_size
                );
                my $width = chars();#use Term::Size::Perl to get terminal width
                if ($width){
                    $ftp->hash(\*STDERR, $file_size/$width);
                }
                my ($sec, $micro) = Time::HiRes::gettimeofday();
                $ftp->get($l) || carp $ftp->message;
                my ($sec2, $micro2) = Time::HiRes::gettimeofday();
                my $local_size = -s $l;
                if ($local_size < $file_size){
                    print STDERR "WARNING - incomplete transfer for file $l ".
                                 "($local_size retrieved, remote file size = ".
                                 "$file_size)\n";
                    if ($self->{_retries}){
                        for (my $att = 1; $att <= $self->{_retries}; $att++){
                            print STDERR "Reattempting transfer of $l... ".
                                         "(attempt " .(1+$att). " of " .
                                         (1 + $self->{_retries}). ")\n";
                            ($sec, $micro) = Time::HiRes::gettimeofday();
                                        $ftp->get($l) || carp $ftp->message;
                            ($sec2, $micro2) = Time::HiRes::gettimeofday();
                            $local_size = -s $l;
                            last if $local_size >= $file_size;
                            print STDERR "WARNING - incomplete transfer for ".
                                         "file $l ($local_size retrieved, ".
                                         "remote file size = $file_size)\n";
                            print STDERR "Transfer failed after " .($att + 1).
                                         " attempts\n" 
                                         if ($att == $self->{_retries});
                        }
                    }
                }
                my $diff = $sec2 - $sec;
                if ($diff){
                    printf STDERR 
                    (
                        "$local_size bytes retrieved in $diff seconds ". 
                        "(%.2f MB/s)\n", 
                        (($local_size/1048576)/$diff)
                    );
                }else{
                    $diff = $micro2 - $micro;
                    printf STDERR 
                    (
                        "$local_size bytes retrieved in $diff microseconds ".
                        "(%.2f MB/s)\n", 
                        (($local_size/1048576)/($diff*10**-6))
                    );
                }
                #print STDERR "-" x $width ."\n" if $width;
                if ($width){
                    #just some vague prettiness/silliness to print
                    print_timed_dashed_line($width, 2000);
                }
            }else{
                print STDERR "Warning - file $l has 0 byte size on remote ".
                             "server.\n";
                $ftp->get($l) or carp $ftp->message;
                my $width = chars();#use Term::Size::Perl to get terminal width
                #print STDERR "-" x $width ."\n" if $width;
                if ($width){
                    #just some vague prettiness/silliness to print
                    print_timed_dashed_line($width, 2000);
                }
            }
        }elsif ($ftp->isdir($l)){
                push (@dirs, $l);
        }
    }
DIR: foreach my $dir (@dirs){
        next if $dir =~ /^\./;
        my $cwd = getcwd();
        #implement _dir_match here
        if ($self->{_dir_match}){
            if ($dir !~ m/$self->{_dir_match}/){
                next DIR;
            }
        }
        get_files_traverse_directories($self, $ftp, $cwd, $dir);
    }
    chdir $root;
    if ($remote_dir){
        if (folder_is_empty($remote_dir) and $self->{_file_match}){
            rmdir $remote_dir or carp "$! ";
        }
    }
    $ftp->cwd($remote_root) 
        or croak "Can't move back to remote directory $remote_root ", 
        $ftp->message;
}

##############################
sub folder_is_empty {
    my $dirname = shift;
    opendir(my $DIR, $dirname) or croak "Directory $dirname doesn't exist - "
        ."internal error. $! ";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($DIR)) == 0;
}

##############################
sub print_timed_dashed_line{
    #arguments are line width and sleep in microseconds 
    my ($width, $sleep) = @_;
    my $old_flush = $|; 
    $| = 1;
    for (my $i = 0; $i < $width; $i++){
        print STDERR "-";
        usleep($sleep);
    }
    print STDERR "\n";
    $| =  $old_flush; #leave $| as we found it.
}

##############################
sub get_sensible_units{
#returns size and units calculated from a value given in bytes
#e.g. 10485700 would return 100 and MB
    my ($bytes) = @_;
    my %convert = 
    (
        bytes   => 1,
        KB      => 1024,
        MB      => 1024 * 1024,
        GB      => 1024 * 1024 * 1024,
        TB      => 1024 * 1024 * 1024 * 1024,
    );
    foreach my $u (qw(bytes KB MB GB TB)){
        my $s = $bytes/$convert{$u};
        if (0 <= $s and $s < 1024){
            return ($s, $u);
        }elsif($u eq "TB"){#TB is the largest unit we'll use
            return ($s, $u);
        }
    }
}

1;
