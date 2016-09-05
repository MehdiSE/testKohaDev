// this function checks id date is like DD/MM/YYYY
function CheckDate(field) {
var d = field.value;
if (d!=="") {
      var amin = 1900;
      var amax = 2100;
      var date = d.split("/");
      var ok=1;
      var msg;
      if ( (date.length < 2) && (ok==1) ) {
        msg = MSG_SEPARATOR.format(field.name);
        alert(msg); ok=0; field.focus();
        return;
      }
      var dd   = date[0];
      var mm   = date[1];
      var yyyy = date[2];
      // checking days
      if ( ((isNaN(dd))||(dd<1)||(dd>31)) && (ok==1) ) {
        msg = MSG_INCORRECT_DAY.format(field.name);
        alert(msg); ok=0; field.focus();
        return false;
      }
      // checking months
      if ( ((isNaN(mm))||(mm<1)||(mm>12)) && (ok==1) ) {
        msg = MSG_INCORRECT_MONTH.format(field.name);
        alert(msg); ok=0; field.focus();
        return false;
      }
      // checking years
      if ( ((isNaN(yyyy))||(yyyy<amin)||(yyyy>amax)) && (ok==1) ) {
        msg = MSG_INCORRECT_YEAR.format(field.name);
        alert(msg); ok=0; field.focus();
        return false;
      }
   }
}

//function test if member is unique and if it's right the member is registred
function unique() {
var msg1;
var msg2;
if (  document.form.check_member.value==1){
    if (document.form.categorycode.value != "I"){

        msg1 += MSG_DUPLICATE_PATRON;
        alert(msg1);
    check_form_borrowers(0);
    document.form.submit();

    }else{
        msg2 += MSG_DUPLICATE_ORGANIZATION;
        alert(msg2);
    check_form_borrowers(0);
    }
}
else
{
    document.form.submit();
}

}
//end function
//function test if date enrooled < date expiry
// WARNING: format-specific test.
function check_manip_date(status) {
if (status=='verify'){
// this part of function('verify') is used to check if dateenrolled<date expiry
if (document.form.dateenrolled !== '' && document.form.dateexpiry.value !=='') {
var myDate1=document.form.dateenrolled.value.split ('/');
var myDate2=document.form.dateexpiry.value.split ('/');
    if ((myDate1[2]>myDate2[2])||(myDate1[2]==myDate2[2] && myDate1[1]>myDate2[1])||(myDate1[2]==myDate2[2] && myDate1[1]>=myDate2[1] && myDate1[0]>=myDate2[0]))

        {
        document.form.dateenrolled.focus();
        var msg = MSG_LATE_EXPIRY;
        alert(msg);
        }
    }
    }
}
//end function

function check_password( password ) {
    if ( password.match(/^\s/) || password.match(/\s$/)) {
        return false;
    }
    return true;
}

// function to test all fields in forms and nav in different forms(1 ,2 or 3)
function check_form_borrowers(nav){
    var statut=0;
    var message = "";
    var message_champ="";
    if (document.form.check_member.value == 1 )
    {
        if (document.form.answernodouble) {
            if( (!(document.form.answernodouble.checked))){
                document.form.nodouble.value=0;
            } else {
                document.form.nodouble.value=1;
            }
        }
    }

    if ( document.form.password.value != document.form.password2.value ){
            if ( message_champ !== '' ){
                message_champ += "\n";
            }
            message_champ+= MSG_PASSWORD_MISMATCH;
            statut=1;
    }

    if ( ! check_password( document.form.password.value ) ) {
        message_champ += MSG_PASSWORD_CONTAINS_TRAILING_SPACES;
        statut = 1;
    }

    //patrons form to test if you checked no to the question of double
    if (statut!=1 && document.form.check_member.value > 0 ) {
        if (!(document.form.answernodouble.checked)){
            message_champ+= MSG_DUPLICATE_SUSPICION;
            statut=1;
            document.form.nodouble.value=0;
        } else {
            document.form.nodouble.value=1;
        }
    }

    if (statut==1){
        //alert if at least 1 error
        alert(message+"\n"+message_champ);
        return false;
    } else {
        return true;
    }
}

function Dopop(link) {
// //   var searchstring=document.form.value[i].value;
    var newin=window.open(link,'popup','width=600,height=400,resizable=no,toolbar=false,scrollbars=no,top');
}

function Dopopguarantor(link) {
    var newin=window.open(link,'popup','width=800,height=500,resizable=no,toolbar=false,scrollbars=yes,top');
}

function clear_entry(node) {
    var original = $(node).parent();
    $("textarea", original).attr('value', '');
    $("select", original).attr('value', '');
}

function clone_entry(node) {
    var original = $(node).parent();
    var clone = original.clone();

    var newId = 50 + parseInt(Math.random() * 100000);
    $("input,select,textarea", clone).attr('id', function() {
        return this.id.replace(/patron_attr_\d+/, 'patron_attr_' + newId);
    });
    $("input,select,textarea", clone).attr('name', function() {
        return this.name.replace(/patron_attr_\d+/, 'patron_attr_' + newId);
    });
    $("label", clone).attr('for', function() {
        return $(this).attr("for").replace(/patron_attr_\d+/, 'patron_attr_' + newId);
    });
    $("input#patron_attr_" + newId, clone).attr('value','');
    $("select#patron_attr_" + newId, clone).attr('value','');
    $(original).after(clone);
    return false;
}

function update_category_code(category_code) {
    if ( $(category_code).is("select") ) {
        category_code = $("#categorycode_entry").find("option:selected").val();
    }
    var mytables = $(".attributes_table");
    $(mytables).find("li").hide();
    $(mytables).find(" li[data-category_code='"+category_code+"']").show();
    $(mytables).find(" li[data-category_code='']").show();
}

function select_user(borrowernumber, borrower) {
    var form = $('#entryform').get(0);
    if (form.guarantorid.value) {
        $("#contact-details").find('a').remove();
        $("#contactname, #contactfirstname").parent().find('span').remove();
    }

    var id = borrower.borrowernumber;
    form.guarantorid.value = id;
    $('#contact-details')
        .show()
        .find('span')
        .after('<a target="blank" href="/cgi-bin/koha/members/moremember.pl?borrowernumber=' + id + '">' + id + '</a>');

    $(form.contactname)
        .val(borrower.surname)
        .before('<span>' + borrower.surname + '</span>').get(0).type = 'hidden';
    $(form.contactfirstname)
        .val(borrower.firstname)
        .before('<span>' + borrower.firstname + '</span>').get(0).type = 'hidden';

    form.streetnumber.value = borrower.streetnumber;
    form.address.value = borrower.address;
    form.address2.value = borrower.address2;
    form.city.value = borrower.city;
    form.state.value = borrower.state;
    form.zipcode.value = borrower.zipcode;
    form.country.value = borrower.country;
    form.branchcode.value = borrower.branchcode;

    form.guarantorsearch.value = LABEL_CHANGE;

    return 0;
}

function CalculateAge(dateofbirth) {
    var today = new Date();
    var dob = Date_from_syspref(dateofbirth);
    var age = {};

    age.year = today.getFullYear() - dob.getFullYear();
    age.month = today.getMonth() - dob.getMonth();
    var day = today.getDate() - dob.getDate();

    if(day < 0) {
        age.month = parseInt(age.month) -1;
    }

    if(age.month < 0) {
        age.year = parseInt(age.year) -1;
        age.month = 12 + age.month;
    }

    return age;
}

function write_age() {
    var hint = $("#dateofbirth").siblings(".hint").first();
    hint.html(dateformat);

    var age = CalculateAge(document.form.dateofbirth.value);

    if (!age.year && !age.month) {
        return;
    }

    var age_string;
    if (age.year || age.month) {
        age_string = LABEL_AGE + ": ";
    }

    if (age.year) {
        age_string += age.year > 1 ? MSG_YEARS.format(age.year) : MSG_YEAR.format(age.year);
        age_string += " ";
    }

    if (age.month) {
        age_string += age.month > 1 ? MSG_MONTHS.format(age.month) : MSG_MONTH.format(age.month);
    }

    hint.html(age_string);
}

$(document).ready(function(){
    if($("#yesdebarred").is(":checked")){
        $("#debarreduntil").show();
    } else {
        $("#debarreduntil").hide();
    }
    $("#yesdebarred,#nodebarred").change(function(){
        if($("#yesdebarred").is(":checked")){
            $("#debarreduntil").show();
            $("#datedebarred").focus();
        } else {
            $("#debarreduntil").hide();
        }
    });
    var mandatory_fields = $("input[name='BorrowerMandatoryField']").val().split ('|');
    $(mandatory_fields).each(function(){
        $("[name='"+this+"']").attr('required', 'required');
    });

    $("fieldset.rows input, fieldset.rows select").addClass("noEnterSubmit");

    $("#guarantordelete").click(function() {
        $("#contact-details").hide().find('a').remove();
        $("#guarantorid, #contactname, #contactfirstname").each(function () { this.value = ""; });
        $("#contactname, #contactfirstname")
            .each(function () { this.type = 'text'; })
            .parent().find('span').remove();
        $("#guarantorsearch").val(LABEL_SET_TO_PATRON);
    });

    $("#select_city").change(function(){
        var myRegEx=new RegExp(/(.*)\|(.*)\|(.*)\|(.*)/);
        document.form.select_city.value.match(myRegEx);
        document.form.zipcode.value=RegExp.$1;
        document.form.city.value=RegExp.$2;
        document.form.state.value=RegExp.$3;
        document.form.country.value=RegExp.$4;
    });

    $("#dateofbirth").datepicker({ maxDate: "-1D", yearRange: "c-120:" });
    dateformat = $("#dateofbirth").siblings(".hint").first().html();

    if( $('#dateofbirth').length ) {
        write_age();
    }

    $("#entryform").validate({
        rules: {
            email: {
                email: true
            },
            emailpro: {
                email: true
            },
            B_email: {
                email: true
            }
        },
        submitHandler: function(form) {
            $("body, form input[type='submit'], form button[type='submit'], form a").addClass('waiting');
            if (form.beenSubmitted)
                return false;
            else
                form.beenSubmitted = true;
                form.submit();
            }
    });

    var mrform = $("#manual_restriction_form");
    var mrlink = $("#add_manual_restriction");
    mrform.hide();
    mrlink.on("click",function(e){
        $(this).hide();
        mrform.show();
        e.preventDefault();
    });

    $("#cancel_manual_restriction").on("click",function(e){
        $('#debarred_expiration').val('');
        $('#add_debarment').val(0);
        $('#debarred_comment').val('');
        mrlink.show();
        mrform.hide();
        e.preventDefault();
    });
    $('#floating-save').css( { bottom: parseInt( $('#floating-save').css('bottom') ) + $('#changelanguage').height() + 'px' } );
});
