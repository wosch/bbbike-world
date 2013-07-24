#!/usr/bin/perl
#
# by http://www.freizeitkarte-osm.de
#
# Usage: set-typ.pl <family id> <product id> <TYP file>
#
# Position of bytes in TYP file:
#
# Little-endian
# Bytes 2f-30: Family ID
# Bytes 31-32: Procuct ID

my $debug = 1;

my $familyID  = shift(@ARGV);
my $productID = shift(@ARGV);

my $typFile = shift(@ARGV);

my $IDsize   = 2;
my $FIDstart = 0x2f;
my $PIDstart = 0x31;

open( TYP, "+<$typFile" ) || die "Can't update $typFile: $!";

warn "Set garmin type: Updating $typFile, familyID: $familyID, productID: $productID\n" if $debug;

seek( TYP, $FIDstart, 0 );
read( TYP, $FID, $IDsize ) == $IDsize || die "can't read FID: $!";

seek( TYP, $PIDstart, 0 );
read( TYP, $PID, $IDsize ) == $IDsize || die "can't read PID: $!";

my $FIDu = unpack( "S", $FID );

my $PIDu = unpack( "S", $PID );

warn "Set garmin type: Original Fid: $FIDu Pid: $PIDu\n" if $debug;

#-----------------
# Change FID, PID:

seek( TYP, $FIDstart, 0 );
print TYP pack( 'S', $familyID );

seek( TYP, $PIDstart, 0 );
print TYP pack( 'S', $productID );

#-----------------

seek( TYP, $FIDstart, 0 );
read( TYP, $FID, $IDsize ) == $IDsize || die "can't read FID: $!";

seek( TYP, $PIDstart, 0 );
read( TYP, $PID, $IDsize ) == $IDsize || die "can't read PID: $!";

$FIDu = unpack( "S", $FID );

$PIDu = unpack( "S", $PID );

warn "Set garmin type: Changed Fid: $FIDu Pid: $PIDu\n" if $debug;

close TYP;

exit;
