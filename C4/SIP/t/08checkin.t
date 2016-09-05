#!/usr/bin/perl
# checkin: test Checkin Response

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Clone qw(clone);

use C4::SIP::Sip::Constants qw(:all);
use SIPtest qw(:basic :user1 :item1);

# Checkout response, format:
# code: 12
# success: 0 or 1
# renewal ok: Y or N
# magnetic media: Y, N or U
# desensitize: Y or N
# date

# Checkin response, format:
# code: 10
# success: 0 or 1
# resensitize: Y or N
# magnetic media: Y, N or U
# alert: Y or N
# date

my $checkout_template = {
    id  => "Checkin: prep: check out item ($item_barcode)",
    msg => "11YN20060329    203000                  AO$instid|AA$user_barcode|AB$item_barcode|AC|",
    pat => qr/^121N[NYU][NY]$datepat/,
    fields => [],
};

my $checkin_test_template = {
    id  => "Checkin: Item ($item_barcode) is checked out",
    msg => "09N20060102    08423620060113    084235AP$item_owner|AO$instid|AB$item_barcode|AC$password|",
    pat => qr/^101[NY][NYU]N$datepat/,
    fields => [
        $SIPtest::field_specs{(FID_INST_ID   )},
        $SIPtest::field_specs{(FID_SCREEN_MSG)},
        $SIPtest::field_specs{(FID_PRINT_LINE)},
        { field    => FID_PATRON_ID,
          pat      => qr/^$user_barcode$/,
          required => 1, },
        { field    => FID_ITEM_ID,
          pat      => qr/^$item_barcode$/,
          required => 1, },
        { field    => FID_PERM_LOCN,
          pat      => $textpat,
          required => 1, },
        { field    => FID_TITLE_ID,
          pat      => qr/^$item_title\s*$/,
          required => 1, }, # not required by the spec.
        { field    => FID_DESTINATION_LOCATION,
          pat      => qr/^$item_owner\s*$/,
          required => 0, }, # 3M Extension
   ],};

my @tests = (
	$SIPtest::login_test,
	$SIPtest::sc_status_test,
	$checkout_template,
	$checkin_test_template,
	);

my $test;

# Checkin item that's not checked out.  Basically, this
# is identical to the first case, except the header says that
# the ILS didn't check the item in, and there's no patron id.
$test = clone($checkin_test_template);
$test->{id}  = 'Checkin: Item not checked out';
$test->{pat} = qr/^100[NY][NYU][NY]$datepat/o;
$test->{fields} = [grep $_->{field} ne FID_PATRON_ID, @{$test->{fields}}];

push @tests, $test;

# 
# Still need tests for magnetic media
# 

SIPtest::run_sip_tests(@tests);

1;
