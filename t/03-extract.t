#!/usr/bin/env perl6

use NativeCall;
use Test;
use lib 'lib';
use Archive::Libarchive::Raw;

my archive $a = archive_read_new;
ok {defined $a}, 'initialization';
is archive_read_support_format_all($a), ARCHIVE_OK, 'use any file format';
is archive_read_support_compression_all($a), ARCHIVE_OK, 'use any compression';
my $file = "t/testdata.tar.gz";
is archive_read_open_filename($a, $file, 10240), ARCHIVE_OK, 'open archive file';
my archive $ext = archive_write_disk_new;
ok {defined $ext}, 'initialized writer';
my int64 $flags = ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
is archive_write_disk_set_options($ext, $flags), ARCHIVE_OK, 'set write options';
is archive_write_disk_set_standard_lookup($ext), ARCHIVE_OK, 'set uname/gname lookup';
my archive_entry $entry .= new;
ok {defined $entry}, 'create entry object';
my $res = archive_read_next_header($a, $entry);
if $res != ARCHIVE_EOF {
  is $res, ARCHIVE_OK, 'read header';
} else {
  bail-out "Can't read the archive header";
}
is archive_write_header($ext, $entry), ARCHIVE_OK, 'write entry header';
ok archive_entry_size($entry) > 0, 'entry size > 0';
my Pointer[void] $buff .= new;
my int64 $size;
my int64 $offset;
is archive_read_data_block($a, $buff, $size, $offset), ARCHIVE_OK, 'read data block';
is archive_write_data_block($ext, $buff, $size, $offset), ARCHIVE_OK, 'write data block';
is archive_write_finish_entry($ext), ARCHIVE_OK, 'finish writing';
is archive_read_close($a), ARCHIVE_OK, 'read_close';
is archive_read_free($a), ARCHIVE_OK, 'read_free';
is archive_write_close($ext), ARCHIVE_OK, 'write_close';
is archive_write_free($ext), ARCHIVE_OK, 'write_free';
is './datafile1'.IO.slurp, "some data\n", 'file extraction';
'./datafile1'.IO.unlink;

done-testing;
