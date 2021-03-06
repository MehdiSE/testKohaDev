[% USE Koha %]
[% USE Branches %]
[% USE Categories %]
<div class="gradient">
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName %]</a></h1><!-- Begin Patrons Resident Search Box -->
<div id="header_search">
    <div id="patron_search" class="residentsearch">
    <p class="tip">Enter patron card number or partial name:</p>
    <form action="/cgi-bin/koha/members/member.pl" method="post">
    <input id="searchmember" data-toggle="tooltip" size="25" class="head-searchbox focus" name="searchmember" type="text" value="[% searchmember %]"/>
    <input type="hidden" name="quicksearch" value="1" />
    <span class="filteraction" id="filteraction_off"> <a href="#">[-]</a></span>
    <span class="filteraction" id="filteraction_on"> <a href="#">[+]</a></span>

    <input value="Search" class="submit" type="submit" />

    <div id="filters">
        <p><label for="searchfieldstype">Search fields:</label>
            <select name="searchfieldstype" id="searchfieldstype">
              [% IF searchfieldstype == "standard" %]
                <option selected="selected" value='standard'>Standard</option>
              [% ELSE %]
                <option value='standard'>Standard</option>
              [% END %]
              [% IF searchfieldstype == "surname" %]
                <option selected="selected" value='surname'>Surname</option>
              [% ELSE %]
                <option value='surname'>Surname</option>
              [% END %]
              [% IF searchfieldstype == "email" %]
                <option selected="selected" value='email'>Email</option>
              [% ELSE %]
                <option value='email'>Email</option>
              [% END %]
              [% IF searchfieldstype == "borrowernumber" %]
                <option selected="selected" value='borrowernumber'>Borrower number</option>
              [% ELSE %]
                <option value='borrowernumber'>Borrower number</option>
              [% END %]
              [% IF searchfieldstype == "userid" %]
                <option selected="selected" value='userid'>Username</option>
              [% ELSE %]
                <option value='userid'>Username</option>
              [% END %]
              [% IF searchfieldstype == "phone" %]
                <option selected="selected" value='phone'>Phone number</option>
              [% ELSE %]
                <option value='phone'>Phone number</option>
              [% END %]
              [% IF searchfieldstype == "address" %]
                <option selected="selected" value='address'>Street Address</option>
              [% ELSE %]
                <option value='address'>Street Address</option>
              [% END %]
              [% IF searchfieldstype == "dateofbirth" %]
                <option selected="selected" value='dateofbirth'>Date of birth</option>
              [% ELSE %]
                <option value='dateofbirth'>Date of birth</option>
              [% END %]
              [% IF searchfieldstype == "sort1" %]
                <option selected="selected" value='sort1'>Sort field 1</option>
              [% ELSE %]
                <option value='sort1'>Sort field 1</option>
              [% END %]
              [% IF searchfieldstype == "sort2" %]
                <option selected="selected" value='sort2'>Sort field 2</option>
              [% ELSE %]
                <option value='sort2'>Sort field 2</option>
              [% END %]
            </select>
        </p>

        <p>
            <label for="searchtype">Search type:</label>
            <select name="searchtype" id="searchtype">
              [% IF searchtype == 'start_with' %]
                  <option selected="selected" value='start_with'>Starts with</option>
                  <option value='contain'>Contains</option>
              [% ELSE %]
                  <option value='start_with'>Starts with</option>
                  <option selected="selected" value='contain'>Contains</option>
              [% END %]
            </select>
        </p>

        <p>
            <label for="branchcode">Library: </label>
            [% SET branches = Branches.all( selected => branchcode_filter ) %]
            <select name="branchcode_filter" id="branchcode">
                [% IF branches.size != 1 %]
                  <option value="">Any</option>
                [% END %]
                [% FOREACH b IN branches %]
                    [% IF b.selected %]
                        <option value="[% b.branchcode %]" selected="selected">[% b.branchname %]</option>
                    [% ELSE %]
                        <option value="[% b.branchcode %]">[% b.branchname %]</option>
                    [% END %]
                [% END %]
            </select>
        </p>

        <p>
            <label for="categorycode">Category: </label>
            [% SET categories = Categories.all( selected => categorycode_filter ) %]
            <select name="categorycode_filter" id="categorycode">
                <option value="">Any</option>
                [% FOREACH categorie IN categories %]
                    [% IF ( categorie.selected ) %]
                        <option value="[% categorie.categorycode %]" selected="selected">[% categorie.description %]</option>
                    [% ELSE %]
                        <option value="[% categorie.categorycode %]">[% categorie.description %]</option>
                    [% END %]
                [% END %]
            </select>
        </p>
    </div>
    </form>
</div>
    [% INCLUDE 'patron-search-box.inc' %]

    [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]
    <div id="checkin_search" class="residentsearch">
    <p class="tip">Scan a barcode to check in:</p>
    <form method="post" action="/cgi-bin/koha/circ/returns.pl" autocomplete="off">
    <input class="head-searchbox" name="barcode" id="ret_barcode" size="40" accesskey="r" />
    <input value="Submit" class="submit" type="submit" />
    </form>
    </div>
        <div id="renew_search" class="residentsearch">
        <p class="tip">Scan a barcode to renew:</p>
            <form method="post" action="/cgi-bin/koha/circ/renew.pl" autocomplete="off">
                <input class="head-searchbox" name="barcode" id="ren_barcode" size="40" />
                <input value="Submit" class="submit" type="submit" />
            </form>
        </div>
    [% END %]

    [% IF ( CAN_user_catalogue ) %]
    <div id="catalog_search" class="residentsearch">
    <p class="tip">Enter search keywords:</p>
        <form action="/cgi-bin/koha/catalogue/search.pl"  method="get" id="cat-search-block">
             <input type="text" name="q" id="search-form" size="40" value="" title="Enter the terms you wish to search for." class="head-searchbox form-text" />
                <input type="submit" name="op" id="opac-submit" value="Submit" class="submit" />
        </form>
    </div>[% END %]

    <ul>
        <li><a onclick="keep_text(0)" href="#patron_search">Search patrons</a></li>
        [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]<li><a onclick="keep_text(1)" href="#circ_search">Check out</a></li>[% END %]
        [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]<li><a onclick="keep_text(2)" href="#checkin_search">Check in</a></li>[% END %]
        [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]<li><a onclick="keep_text(3)" href="#renew_search">Renew</a></li>[% END %]
        [% IF ( CAN_user_catalogue ) %]<li><a onclick="keep_text(4)" href="#catalog_search">Search the catalog</a></li>[% END %]
    </ul>
</div><!-- /header_search -->
</div><!-- /gradient -->
<script type="text/javascript">//<![CDATA[
$(document).ready(function() {
    $("#filteraction_off, #filteraction_on").on('click', function(e) {
        e.preventDefault();
        $('#filters').toggle();
        $('.filteraction').toggle();
    });
    [% IF ( advsearch ) %]$("#filteraction_on").toggle();
    [% ELSE %]$("#filters").toggle();
    $("#filteraction_off").toggle();[% END %]
    [% SET dateformat = Koha.Preference('dateformat') %]
    $("#searchfieldstype").change(function() {
      if ( $(this).val() == 'dateofbirth' ) {
          [% IF dateformat == 'us' %]
              var MSG_DATE_FORMAT = _("Dates of birth should be entered in the format 'MM/DD/YYYY'");
          [% ELSIF dateformat == 'iso' %]
              var MSG_DATE_FORMAT = _("Dates of birth should be entered in the format 'YYYY-MM-DD'");
          [% ELSIF dateformat == 'metric' %]
              var MSG_DATE_FORMAT = _("Dates of birth should be entered in the format 'DD/MM/YYYY'");
          [% ELSIF dateformat == 'dmydot' %]
              var MSG_DATE_FORMAT = _("Dates of birth should be entered in the format 'DD.MM.YYYY'");
          [% END %]
          $('#searchmember').attr("title",MSG_DATE_FORMAT).tooltip('show');
      } else {
          $('#searchmember').tooltip('destroy');
      }
    });
});
//]]>
</script>
<!-- End Patrons Resident Search Box -->
