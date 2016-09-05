#!/usr/bin/perl

# Copyright 2015 Koha Team
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

use Modern::Perl;
use CGI qw ( -utf8 );
use C4::Auth;
use C4::Biblio;
use C4::Koha;
use C4::Items;
use C4::Members;
use C4::Output;
use C4::Tags qw( get_tags );
use C4::XSLT;
use Koha::Virtualshelves;

my $query = new CGI;

my $template_name = $query->param('rss') ? "opac-shelves-rss.tt" : "opac-shelves.tt";

# if virtualshelves is disabled, leave immediately
if ( ! C4::Context->preference('virtualshelves') ) {
    print $query->redirect("/cgi-bin/koha/errors/404.pl");
    exit;
}

my ( $template, $loggedinuser, $cookie ) = get_template_and_user({
        template_name   => $template_name,
        query           => $query,
        type            => "opac",
        authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
    });

my $op       = $query->param('op')       || 'list';
my $referer  = $query->param('referer')  || $op;
my $category = $query->param('category') || 1;
my ( $shelf, $shelfnumber, @messages );

if ( $op eq 'add_form' ) {
    # Nothing to do
} elsif ( $op eq 'edit_form' ) {
    $shelfnumber = $query->param('shelfnumber');
    $shelf       = Koha::Virtualshelves->find($shelfnumber);

    if ( $shelf ) {
        $category = $shelf->category;
        my $patron = GetMember( 'borrowernumber' => $shelf->owner );
        $template->param( owner => $patron, );
        unless ( $shelf->can_be_managed( $loggedinuser ) ) {
            push @messages, { type => 'error', code => 'unauthorized_on_update' };
            $op = 'list';
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
} elsif ( $op eq 'add' ) {
    if ( $loggedinuser ) {
        eval {
            $shelf = Koha::Virtualshelf->new(
                {   shelfname          => scalar $query->param('shelfname'),
                    sortfield          => scalar $query->param('sortfield'),
                    category           => scalar $query->param('category') || 1,
                    allow_add          => scalar $query->param('allow_add'),
                    allow_delete_own   => scalar $query->param('allow_delete_own'),
                    allow_delete_other => scalar $query->param('allow_delete_other'),
                    owner              => scalar $loggedinuser,
                }
            );
            $shelf->store;
            $shelfnumber = $shelf->shelfnumber;
        };
        if ($@) {
            push @messages, { type => 'error', code => ref($@), msg => $@ };
        } elsif ( not $shelf ) {
            push @messages, { type => 'error', code => 'error_on_insert' };
        } else {
            push @messages, { type => 'message', code => 'success_on_insert' };
            $op = 'view';
        }
    } else {
        push @messages, { type => 'error', code => 'unauthorized_on_insert' };
        $op = 'list';
    }
} elsif ( $op eq 'edit' ) {
    $shelfnumber = $query->param('shelfnumber');
    $shelf       = Koha::Virtualshelves->find($shelfnumber);
    if ( $shelf ) {
        $op = $referer;
        if ( $shelf->can_be_managed( $loggedinuser ) ) {
            $shelf->shelfname( $query->param('shelfname') );
            $shelf->sortfield( $query->param('sortfield') );
            $shelf->allow_add( $query->param('allow_add') );
            $shelf->allow_delete_own( $query->param('allow_delete_own') );
            $shelf->allow_delete_other( $query->param('allow_delete_other') );
            $shelf->category( $query->param('category') );
            eval { $shelf->store };

            if ($@) {
                push @messages, { type => 'error', code => 'error_on_update' };
                $op = 'edit_form';
            } else {
                push @messages, { type => 'message', code => 'success_on_update' };
            }
        } else {
            push @messages, { type => 'error', code => 'unauthorized_on_update' };
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
} elsif ( $op eq 'delete' ) {
    $shelfnumber = $query->param('shelfnumber');
    $shelf       = Koha::Virtualshelves->find($shelfnumber);
    if ($shelf) {
        if ( $shelf->can_be_deleted( $loggedinuser ) ) {
            eval { $shelf->delete; };
            if ($@) {
                push @messages, { type => 'error', code => ref($@), msg => $@ };
            } else {
                push @messages, { type => 'message', code => 'success_on_delete' };
            }
        } else {
            push @messages, { type => 'error', code => 'unauthorized_on_delete' };
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
    $op = $referer;
} elsif ( $op eq 'remove_share' ) {
    $shelfnumber = $query->param('shelfnumber');
    $shelf = Koha::Virtualshelves->find($shelfnumber);
    if ($shelf) {
        my $removed = eval { $shelf->remove_share( $loggedinuser ); };
        if ($@) {
            push @messages, { type => 'error', code => ref($@), msg => $@ };
        } elsif ( $removed ) {
            push @messages, { type => 'message', code => 'success_on_remove_share' };
        } else {
            push @messages, { type => 'error', code => 'error_on_remove_share' };
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
    $op = $referer;

} elsif ( $op eq 'add_biblio' ) {
    $shelfnumber = $query->param('shelfnumber');
    $shelf = Koha::Virtualshelves->find($shelfnumber);
    if ($shelf) {
        if( my $barcode = $query->param('barcode') ) {
            my $item = GetItem( 0, $barcode);
            if (defined $item && $item->{itemnumber}) {
                my $biblio = GetBiblioFromItemNumber( $item->{itemnumber} );
                if ( $shelf->can_biblios_be_added( $loggedinuser ) ) {
                    my $added = eval { $shelf->add_biblio( $biblio->{biblionumber}, $loggedinuser ); };
                    if ($@) {
                        push @messages, { type => 'error', code => ref($@), msg => $@ };
                    } elsif ( $added ) {
                        push @messages, { type => 'message', code => 'success_on_add_biblio' };
                    } else {
                        push @messages, { type => 'message', code => 'error_on_add_biblio' };
                    }
                } else {
                    push @messages, { type => 'error', code => 'unauthorized_on_add_biblio' };
                }
            } else {
                push @messages, { type => 'error', code => 'item_does_not_exist' };
            }
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
    $op = $referer;
} elsif ( $op eq 'remove_biblios' ) {
    $shelfnumber = $query->param('shelfnumber');
    $shelf = Koha::Virtualshelves->find($shelfnumber);
    my @biblionumber = $query->multi_param('biblionumber');
    if ($shelf) {
        if ( $shelf->can_biblios_be_removed( $loggedinuser ) ) {
            my $number_of_biblios_removed = eval {
                $shelf->remove_biblios(
                    {
                        biblionumbers => \@biblionumber,
                        borrowernumber => $loggedinuser,
                    }
                );
            };
            if ($@) {
                push @messages, { type => 'error', code => ref($@), msg => $@ };
            } elsif ( $number_of_biblios_removed ) {
                push @messages, { type => 'message', code => 'success_on_remove_biblios' };
            } else {
                push @messages, { type => 'error', code => 'no_biblio_removed' };
            }
        } else {
            push @messages, { type => 'error', code => 'unauthorized_on_remove_biblios' };
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
    $op = 'view';
}

if ( $op eq 'view' ) {
    $shelfnumber ||= $query->param('shelfnumber');
    $shelf = Koha::Virtualshelves->find($shelfnumber);
    if ( $shelf ) {
        if ( $shelf->can_be_viewed( $loggedinuser ) ) {
            $category = $shelf->category;
            my $sortfield = $query->param('sortfield') || $shelf->sortfield;    # Passed in sorting overrides default sorting
            my $direction = $query->param('direction') || 'asc';
            $direction = 'asc' if $direction ne 'asc' and $direction ne 'desc';
            my ( $page, $rows );
            unless ( $query->param('print') or $query->param('rss') ) {
                $rows = C4::Context->preference('OPACnumSearchResults') || 20;
                $page = ( $query->param('page') ? $query->param('page') : 1 );
            }
            my $order_by = $sortfield eq 'itemcallnumber' ? 'items.itemcallnumber' : $sortfield;
            my $contents = $shelf->get_contents->search(
                {},
                {
                    prefetch => [ { 'biblionumber' => { 'biblioitems' => 'items' } } ],
                    page     => $page,
                    rows     => $rows,
                    order_by => { "-$direction" => $order_by },
                }
            );

            # get biblionumbers stored in the cart
            my @cart_list;
            if(my $cart_list = $query->cookie('bib_list')){
                @cart_list = split(/\//, $cart_list);
            }

            my $borrower = GetMember( borrowernumber => $loggedinuser );

            my $xslfile = C4::Context->preference('OPACXSLTResultsDisplay');
            my $lang   = $xslfile ? C4::Languages::getlanguage()  : undef;
            my $sysxml = $xslfile ? C4::XSLT::get_xslt_sysprefs() : undef;

            my @items;
            while ( my $content = $contents->next ) {
                my $biblionumber = $content->biblionumber->biblionumber;
                my $this_item    = GetBiblioData($biblionumber);
                my $record       = GetMarcBiblio($biblionumber);

                if ( $xslfile ) {
                    $this_item->{XSLTBloc} = XSLTParse4Display( $biblionumber, $record, "OPACXSLTResultsDisplay",
                                                                1, undef, $sysxml, $xslfile, $lang);
                }

                my $marcflavour = C4::Context->preference("marcflavour");
                my $itemtypeinfo = getitemtypeinfo( $content->biblionumber->biblioitems->first->itemtype, 'opac' );
                $this_item->{imageurl}          = $itemtypeinfo->{imageurl};
                $this_item->{description}       = $itemtypeinfo->{description};
                $this_item->{notforloan}        = $itemtypeinfo->{notforloan};
                $this_item->{'coins'}           = GetCOinSBiblio($record);
                $this_item->{'subtitle'}        = GetRecordValue( 'subtitle', $record, GetFrameworkCode( $biblionumber ) );
                $this_item->{'normalized_upc'}  = GetNormalizedUPC( $record, $marcflavour );
                $this_item->{'normalized_ean'}  = GetNormalizedEAN( $record, $marcflavour );
                $this_item->{'normalized_oclc'} = GetNormalizedOCLCNumber( $record, $marcflavour );
                $this_item->{'normalized_isbn'} = GetNormalizedISBN( undef, $record, $marcflavour );

                unless ( defined $this_item->{size} ) {

                    #TT has problems with size
                    $this_item->{size} = q||;
                }

                # Getting items infos for location display
                my @items_infos = &GetItemsLocationInfo( $biblionumber );
                $this_item->{'ITEM_RESULTS'} = \@items_infos;

                if (C4::Context->preference('TagsEnabled') and C4::Context->preference('TagsShowOnList')) {
                    $this_item->{TagLoop} = get_tags({
                        biblionumber => $biblionumber, approved=>1, 'sort'=>'-weight',
                        limit => C4::Context->preference('TagsShowOnList'),
                    });
                }

                $this_item->{allow_onshelf_holds} = C4::Reserves::OnShelfHoldsAllowed($this_item, $borrower);


                if ( grep {$_ eq $biblionumber} @cart_list) {
                    $this_item->{incart} = 1;
                }

                if ( $query->param('rss') ) {
                    $this_item->{title} = $content->biblionumber->title;
                    $this_item->{author} = $content->biblionumber->author;
                }

                $this_item->{biblionumber} = $biblionumber;
                push @items, $this_item;
            }

            $template->param(
                can_manage_shelf   => $shelf->can_be_managed($loggedinuser),
                can_delete_shelf   => $shelf->can_be_deleted($loggedinuser),
                can_remove_biblios => $shelf->can_biblios_be_removed($loggedinuser),
                can_add_biblios    => $shelf->can_biblios_be_added($loggedinuser),
                sortfield          => $sortfield,
                itemsloop          => \@items,
                sortfield          => $sortfield,
                direction          => $direction,
            );
            if ( $page ) {
                my $pager = $contents->pager;
                $template->param(
                    pagination_bar => pagination_bar(
                        q||, $pager->last_page - $pager->first_page + 1,
                        $page, "page", { op => 'view', shelfnumber => $shelf->shelfnumber, sortfield => $sortfield, direction => $direction, }
                    ),
                );
            }
        } else {
            push @messages, { type => 'error', code => 'unauthorized_on_view' };
        }
    } else {
        push @messages, { type => 'error', code => 'does_not_exist' };
    }
}

if ( $op eq 'list' ) {
    my $shelves;
    my ( $page, $rows ) = ( $query->param('page') || 1, 20 );
    if ( $category == 1 ) {
        $shelves = Koha::Virtualshelves->get_private_shelves({ page => $page, rows => $rows, borrowernumber => $loggedinuser, });
    } else {
        $shelves = Koha::Virtualshelves->get_public_shelves({ page => $page, rows => $rows, });
    }

    my $pager = $shelves->pager;
    $template->param(
        shelves => $shelves,
        pagination_bar => pagination_bar(
            q||, $pager->last_page - $pager->first_page + 1,
            $page, "page", { op => 'list', category => $category, }
        ),
    );
}

$template->param(
    op       => $op,
    referer  => $referer,
    shelf    => $shelf,
    messages => \@messages,
    category => $category,
    print    => scalar $query->param('print') || 0,
    listsview => 1,
);

output_html_with_http_headers $query, $cookie, $template->output;
