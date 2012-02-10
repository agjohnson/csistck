package Csistck::Util;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
use FindBin;
use File::Copy;

our @EXPORT_OK = qw/
    backup_file
    hash_file
    hash_string
    package_manager
/;

use Csistck::Oper qw/debug info/;
use Csistck::Config qw/option/;

# Backup single file
sub backup_file {
    my $file = shift;

    debug("Backing up file: <file=$file>");
    
    # Get absolute backup path
    my $dest_base = option('backup_path') // join '/', $FindBin::Bin, 'backup';
    die("Backup path does not exist: path=<$dest_base>")
      if (! -e $dest_base);
    die("Backup path is not writable: path=<$dest_base>")
      if (-e $dest_base and ! -w $dest_base);    
    
    # Get file hash, use this is a file name to copy to
    my $hash = hash_file($file);
    my $dest = join '/', $dest_base, $hash;

    copy($file, $dest) or die("Backup failed: $!: file=<$file> dest=<$dest>");

    info("Backup succeeded: file=<$file> dest=<$dest>");
}

# Hash file, return hash or die if error
sub hash_file {
    my $file = shift;

    debug("Hashing file: file=<$file>");

    # Errors to die on
    die("File does not exist: file=<$file>")
      if (! -e $file);
    die("File not readable: file=<$file>")
      if (! -r $file);

    open(my $h, $file) or die("Error opening file: $!: file=<$file>");
        
    my $hash = Digest::MD5->new();
    $hash->addfile($h);
    close($h);

    my $digest = $hash->hexdigest();

    debug(sprintf "File hash successful: file=<%s> hash=<%s>", $file, $digest);

    return $digest;    
}

# Returns md5 hash of input string
sub hash_string {
    my $string = shift;

    my $hash = Digest::MD5->new();
    $hash->add($string);

    return $hash->hexdigest();
}

1;
