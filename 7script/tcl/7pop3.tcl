# 7pop3.tcl - Class to poll POP3 server 
#

package provide 7pop3 1.0

namespace eval 7pop3 {
    variable sock

}


proc ::7pop3::open {host {port 110}} {
    variable sock


    if [catch {socket -async $host $port} sock] {
	error "POP3 open failed to $host because: $sock"
    }

    fconfigure $sock \
	-blocking    yes \
	-buffering   none \
	-translation crlf

    set greeting [getResult]
    if ![checkResult $greeting] {
	error "POP3 protocol failed to $host with: $greeting"
    }

}

proc ::7pop3::login {user pass} {
    variable sock

    wrsock "user $user"
    set r [getResult]
    checkResult $r

    wrsock "pass $pass"
    set r [getResult]
    checkResult $r
}

proc ::7pop3::quit {} {
    variable sock

    wrsock "quit"
    set r [getResult]

    close $sock
    unset sock
}

proc ::7pop3::getResult {} {
    variable sock

    set line [gets $sock]
    return $line
}

proc ::7pop3::checkResult {result} {
    switch -regexp $result {
	{^[+]} { return 1 }
	{^-} { return 0 }
    }
    return 0
}

proc ::7pop3::wrsock {txt} {
    variable sock

    # FOR DEBUGGING
    #puts ">>>> $txt"
    puts $sock $txt
}

