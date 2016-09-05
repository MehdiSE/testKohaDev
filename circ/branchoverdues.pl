#!/usr/bin/perl

#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use strict;
#use warnings; FIXME - Bug 2505
use C4::Context;
use CGI qw ( -utf8 );
use C4::Output;
use C4::Auth;
use C4::Overdues;    # AddNotifyLine
use C4::Biblio;
use C4::Koha;
use C4::Debug;
use C4::Branch;
use Koha::DateUtils;
use Data::Dumper;

=head1 branchoverdues.pl

 this module is a new interface, allow to the librarian to check all items on overdues (based on the acountlines type 'FU' )
 this interface is filtered by branches (automatically), and by location (optional) ....
 all informations are stocked in the notifys BDD

 FIXME for this time, we have only four methods to notify :
 	- mail : work with a batch programm
 	- letter : for us, the letters are generated by an open-office program
 	- phone : Simple method, when the method 'phone' is selected, we consider, that the borrower as been notified, and the notify send date is implemented
 	- considered lost : for us if the document is on the third overduelevel,

 FIXME the methods are actually hardcoded for the levels : (maybe can be improved by a new possibility in overduerule)

 	level 1 : three methods are possible : - mail, letter, phone
 	level 2 : only one method is possible : - letter
 	level 3 : only methode is possible  : - Considered Lost

 	the documents displayed on this interface, are checked on three points
 	- 1) the document must be on accountlines (Type 'FU')
 	- 2) item issues is not returned
	- 3) this item as not been already notify

  FIXME: who is the author?
  FIXME: No privisions (i.e. "actions") for handling notices are implemented.
  FIXME: This is linked as "Overdue Fines" but the relationship to fines in GetOverduesForBranch is more complicated than that.

=cut

my $input       = new CGI;
my $dbh = C4::Context->dbh;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user({
        template_name   => "circ/branchoverdues.tt",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { circulate => "circulate_remaining_permissions" },
        debug           => 1,
});

my $default = C4::Context->userenv->{'branch'};

# Deal with the vars recept from the template
my $borrowernumber = $input->param('borrowernumber');
my $itemnumber     = $input->param('itemnumber');
my $method         = $input->param('method');
my $overduelevel   = $input->param('overduelevel');
my $notifyId       = $input->param('notifyId');
my $location       = $input->param('location');

# FIXME: better check that borrowernumber is defined and valid.
# FIXME: same for itemnumber and other variables passed in here.

# now create the line in bdd (notifys)
if ( $input->param('action') eq 'add' ) {
    my $addnotify =
      AddNotifyLine( $borrowernumber, $itemnumber, $overduelevel, $method,
        $notifyId )    # FIXME: useless variable, no TMPL code for "action" exists.;
}
elsif ( $input->param('action') eq 'remove' ) {
    my $notify_date  = $input->param('notify_date');
    my $removenotify =
      RemoveNotifyLine( $borrowernumber, $itemnumber, $notify_date );    # FIXME: useless variable, no TMPL code for "action" exists.
}

my @overduesloop;
my @getoverdues = GetOverduesForBranch( $default, $location );
$debug and warn "HERE : $default / $location" . Dumper(@getoverdues);
# search for location authorised value
my ($tag,$subfield) = GetMarcFromKohaField('items.location','');
my $tagslib = &GetMarcStructure(1,'');
if ($tagslib->{$tag}->{$subfield}->{authorised_value}) {
    my $values= GetAuthorisedValues($tagslib->{$tag}->{$subfield}->{authorised_value});
    for (@$values) { $_->{selected} = 1 if $location eq $_->{authorised_value} }
    $template->param(locationsloop => $values);
}
# now display infos
foreach my $num (@getoverdues) {
    my %overdueforbranch;
    my $record = GetMarcBiblio($num->{biblionumber});
    if ($record){
        $overdueforbranch{'subtitle'} = GetRecordValue('subtitle',$record,'')->[0]->{subfield};
    }
    my $dt = dt_from_string($num->{date_due}, 'sql');
    $overdueforbranch{'date_due'}          = output_pref($dt);
    $overdueforbranch{'title'}             = $num->{'title'};
    $overdueforbranch{'description'}       = $num->{'description'};
    $overdueforbranch{'barcode'}           = $num->{'barcode'};
    $overdueforbranch{'biblionumber'}      = $num->{'biblionumber'};
    $overdueforbranch{'author'}            = $num->{'author'};
    $overdueforbranch{'borrowersurname'}   = $num->{'surname'};
    $overdueforbranch{'borrowerfirstname'} = $num->{'firstname'};
    $overdueforbranch{'borrowerphone'}     = $num->{'phone'};
    $overdueforbranch{'borroweremail'}     = $num->{'email'};
    $overdueforbranch{'homebranch'}        = GetBranchName($num->{'homebranch'});
    $overdueforbranch{'itemcallnumber'}    = $num->{'itemcallnumber'};
    $overdueforbranch{'borrowernumber'}    = $num->{'borrowernumber'};
    $overdueforbranch{'itemnumber'}        = $num->{'itemnumber'};
    $overdueforbranch{'cardnumber'}        = $num->{'cardnumber'};

    # now we add on the template, the differents values of notify_level
    # FIXME: numerical comparison, not string eq.
    if ( $num->{'notify_level'} eq '1' ) {
        $overdueforbranch{'overdue1'}     = 1;
        $overdueforbranch{'overdueLevel'} = 1;
    }
    elsif ( $num->{'notify_level'} eq '2' ) {
        $overdueforbranch{'overdue2'}     = 1;
        $overdueforbranch{'overdueLevel'} = 2;
    }
    elsif ( $num->{'notify_level'} eq '3' ) {
        $overdueforbranch{'overdue3'}     = 1;
        $overdueforbranch{'overdueLevel'} = 3;
    }
    $overdueforbranch{'notify_id'} = $num->{'notify_id'};

    push( @overduesloop, \%overdueforbranch );
}

# initiate the templates for the overdueloop
$template->param(
    overduesloop => \@overduesloop,
    location     => $location,
);

output_html_with_http_headers $input, $cookie, $template->output;
