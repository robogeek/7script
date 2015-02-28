# 7smtp.tcl - class to send SMTP email
#
#	IMPLEMENTS 
#		RFC 821  SMTP
#		RFC 1426 SMTP-EXT
#
# Only enough of SMTP-EXT was implemented to
# recognize the keywords.  The extended keywords
# on addresses is not supported (this would be
# easy to implement).
#
# It does not strip the 8th bit.
#
# I don't know if the error handling is right.
#

package provide 7smtp 1.0

namespace eval 7smtp {
    variable sock
    variable greeting
    variable isSmtpExt

    variable SMTPEXT
    set SMTPEXT(junk) ""
    unset SMTPEXT(junk)
	
    variable isopen
    set isopen 0
}

#
# ::7smtp::open - Open an SMTP connection to the given host.
#
# @param host   The host/domain we are sending the mail to
# @param domain The domain to identify ourselves in the HELO command
#
proc ::7smtp::open {host domain {port 25}} {
    variable sock
    variable greeting
    variable isSmtpExt
    variable SMTPEXT

    set useDnsMX 0
    
    if $useDnsMX {
        if [catch {dns mx $host} mxList] {  # Requires scotty
            #puts "Cannot find $host in DNS because $mxList"
            error "Cannot find $host in DNS because $mxList"
        }
    
	set hosts [lsort -increasing -index 1 $mxList]

    	#puts "\n$host: $hosts"
	foreach mx $hosts {
	    set host [lindex $mx 0]
	    #puts -nonewline "... Trying $host"
	    if [catch {socket -async $host $port} sock] {
		error "Failed to open SMTP connection with $host because: $sock"
		#puts " ... FAILED"
	    } else {
		#puts " ... WORKED"
		break
	    }
	}
    } else {

	if [catch {socket -async $host $port} sock] {
	    error "Failed to open SMTP connection with $host because: $sock"
	}
    }

    fconfigure $sock \
	-blocking    yes \
	-buffering   none \
	-translation crlf

    set greeting [getResult]
    if [checkResult $greeting] {
	#puts "Cannot connect to server $host because [lindex $greeting 1]"
	error "Cannot connect to server $host because [lindex $greeting 1]"
    }

    wrsock "EHLO $domain"
    set result [getResult]

    if [checkResult $result] {
	set isSmtpExt 0
	
	wrsock "HELO $domain"
	set result [getResult]
	if [checkResult $result] {
	    #puts "Cannot connect to server $host because [lindex $result 1]"
	    error "Cannot connect to server $host because [lindex $result 1]"
	}
    } else {
	set isSmtpExt 1

	foreach ehloLine [lrange [split [lindex $result 1] "\n"] 1 end] {
	    # Here parse the line to catch the keyword/parms

	    if [regexp {^([A-Za-z0-9][-A-Za-z0-9]*) (.*)$} \
		    $ehloLine junk keyword parm] {
		
		set SMTPEXT($keyword) $parm
	    } elseif [regexp {^([A-Za-z0-9][-A-Za-z0-9]*)} \
			  $ehloLine junk keyword] {

		set SMTPEXT($keyword) ""
	    }

	}
    }
	
    variable isopen
    set isopen 1
}
namespace eval 7smtp { namespace export open }

#
# ::7smtp::mailFrom - Declare who the mail is from
#
proc ::7smtp::mailFrom {email} {
    variable sock

    wrsock "MAIL FROM:<$email>"
    set result [getResult]

    if [checkResult $result] {
	error "Failed to send to $email because [lindex $result 1]"
    } else {
	return 0
    }
}
namespace eval 7smtp { namespace export mailFrom }

#
# ::7smtp::rcptTo - Declare a recipient for the mail
#
proc ::7smtp::rcptTo {email} {
    variable sock

    wrsock "RCPT TO:<$email>"
    set result [getResult]

    if [checkResult $result] {
	error "$email FAILED([lindex $result 0]): [lindex $result 1]"
    } else {
	return 0
    }
}
namespace eval 7smtp { namespace export rcptTo }

#
# ::7smtp::data - Send the message data.  Note that all the translation to
#   the SMTP transport format is handled by the ::7smtp package.
#
# *) Recall that message data is a complete RFC-822 formatted message
#  header and body.
#
# *) In your data, end each line with just \n.  SMTP requires that
#   data in the protocol end lines with \r\n, however in ::7smtp::open
#   we specified 'translation crlf' which does the \n->\r\n conversion.
#
# *) For lines beginning with '.', SMTP requires that an extra '.' 
#   be prepended.  That is done here.
#
proc ::7smtp::data {data} {
    variable sock

    wrsock "DATA"
    set result [getResult]
    
    foreach line [split $data "\n"] {
	regsub {^\.(.*)$} $line {..\1} line
	wrsock $line
    }

    wrsock "."
    set result [getResult]

    if [checkResult $result] {
	error "Failed to send mail because [lindex $result 1]"
    } else {
	return 0
    }
}
namespace eval 7smtp { namespace export data }

#
# ::7smtp::data - Reset the connection
#
proc ::7smtp::reset {} {

    variable sock

    wrsock "RSET"
    set result [getResult]
    
    if [checkResult $result] {
	error "Failed to reset because [lindex $result 1]"
    } else {
	return [lindex $result 1]
    }
}
namespace eval 7smtp { namespace export reset }

#
# ::7smtp::verify - Verify that this address is correct.
#
proc ::7smtp::verify {email} {
    variable sock

    wrsock "VRFY $email"
    set result [getResult]

    if [checkResult $result] {
	error "Failed to verify $email because [lindex $result 1]"
    } else {
	return [lindex $result 1]
    }
}
namespace eval 7smtp { namespace export verify }

#
# ::7smtp::expand - Find out where this address delivers to.  For a mailing list
#  this will (usually) return the list members, or if the mail is forwarded
#  to an alias the alias is returned.
#
proc ::7smtp::expand {email} {
    variable sock

    wrsock "EXPN $email"
    set result [getResult]
    
    if [checkResult $result] {
	error "Failed to expand $email because [lindex $result 1]"
    } else {
	return [lindex $result 1]
    }
}
namespace eval 7smtp { namespace export expand }

#
# ::7smtp::quit - Tell the SMTP server we are closing the connection,
#   and close it out.
#
proc ::7smtp::quit {} {

    variable sock
    variable greeting
    variable isSmtpExt
    variable SMTPEXT
    variable isopen

    if {$isopen == 0} { return }
	
    wrsock "QUIT"
    set result [getResult]

    close
}
namespace eval 7smtp { namespace export quit }

#
# ::7smtp::close - Close the connection.
#
proc ::7smtp::close {} {
    variable sock
    variable greeting
    variable isSmtpExt
    variable SMTPEXT
    variable isopen
	
    if {$isopen == 0} { return }
	
    ::close $sock
    set isopen 0
  
    unset sock
    unset greeting
    unset isSmtpExt
    
    foreach index [array names SMTPEXT] {
	unset SMTPEXT($index)
    }
}
namespace eval 7smtp { namespace export close }

#
# ::7smtp::smdate - Return a date string for the current time
#   in the format specified by RFC-822.
#
proc ::7smtp::smdate {} {
    set sec [clock seconds]
    return [clock format $sec -format "%a, %d %b %Y %H:%M:%S -0000" -gmt true]
}
namespace eval 7smtp { namespace export smdate }

namespace eval 7smtp {
    proc exports {} {
	return [namespace export]
    }
}

 proc ::7smtp::wrsock {txt} {
    variable sock

    # FOR DEBUGGING
    #puts ">>>> $txt"
    puts $sock $txt
}

 proc ::7smtp::getResult {} {
    variable sock

    set resText ""
    set codes   ""

    for {set line [gets $sock]} \
	1 \
	{set line [gets $sock]} {

	    #puts "<<<< $line"

	    if [regexp {^([0-9][0-9][0-9])([- ])(.*)$} $line junk \
		    code contin text] {

		lappend codes $code
		if {$resText != ""} { append resText "\n" }
		append resText $text

		if {$contin != "-"} {
		    break
		}
	    } else {
		break
	    }
	}

    return [list $codes $resText]
}

 proc ::7smtp::checkResult {resInfo} {

    set codes [lindex $resInfo 0]

    #puts $codes
    foreach code $codes {
	#puts -nonewline "$code ..."
	switch -regexp $code {
	    {^1..}  { continue }
	    {^2..}  { continue }
	    {^3..}  { continue }
	    {^4..}  { return 1 }
	    {^5..}  { return 1 }
	}
    }

    return 0
}
