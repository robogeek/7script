# 7sql.tcl - Base package to wrap around SQL server 

package provide 7sql 1.0
package require 7oo

class ::7sql {

    ###############
    # DB ACCESS   #
    ###############

    variable public scalar dbHost  ""   ;# The host the database is on
    proc public setSqlDbHost {host} { variable dbHost; set dbHost $host  }
    proc public getSqlDbHost {}     { variable dbHost; return $dbHost    }

    variable public scalar dbUser  ""   ;# The user name to log in to the database
    proc public setSqlDbUser {user} { variable dbUser; set dbUser $user  }
    proc public getSqlDbUser {}     { variable dbUser; return $dbUser    }

    variable public scalar dbPassword ""   ;# The password for the database
    proc public setSqlDbPassword {pwd} { variable dbPassword; set dbPassword $pwd }
    proc public getSqlDbPassword {}    { variable dbPassword; return $dbPassword  }

    variable public scalar dbName  ""      ;# The name of the database
    proc public getSqlDbName {}     { variable dbName; return $dbName   }
    proc public setSqlDbName {name} { variable dbName; set dbName $name }

    variable public scalar dbHandle ""     ;# The MySQL handle to the database
    proc public getSqlDbHandle {} { variable dbHandle; return $dbHandle}

    proc public 7sql {} {  }

    ##################################
    # Opening & closing the database #
    ##################################

    proc public sqlOpenDb {} {
	variable dbPassword
	variable dbUser
	variable dbHost
	variable dbHandle

	set dbHandle [mysqlconnect -user $dbUser -password $dbPassword $dbHost]
    }

    proc public sqlCloseDb {} {
	variable dbHandle
	variable dbName

	mysqlclose $dbHandle
	set dbHandle ""
	set dbName ""
    }

    proc public sqlUseDb {{name ""}} {
	variable dbName
	variable dbHandle

	if {$name != ""} {
	    set dbName $name
	}
	if {$dbName == ""} {
	    error "No database name to use"
	}
	mysqluse $dbHandle $dbName
    }

    proc public sqlIsOpen {} {
	variable dbHandle;
	if {$dbHandle != ""} { 
	    return 1
	} else {
	    return 0
	}
    }

    ####################
    # mysqlsel command #
    ####################

    proc public sqlselect {cmd} { 
	variable dbHandle
	if [catch {mysqlsel $dbHandle $cmd} ret] {
	    error "sqlsqlect $cmd; failed because $ret"
	} else {
	    return $ret
	}
	
    }

    #####################
    # mysqlexec command #
    #####################

    proc public sqlexec {cmd} {
	variable dbHandle
	if [catch {mysqlexec $dbHandle $cmd} ret] {
	    error "sqlexec $cmd; failed because $ret"
	} else {
	    return $ret
	}
    }

    #####################
    # mysqlnext command #
    #####################

    proc public sqlGetFullResult {} {
	variable dbHandle

	set res ""
	for {set row [mysqlnext $dbHandle]} {$row != ""} {set row [mysqlnext $dbHandle]} {
	    lappend res $row
	}

	return $res
    }

    proc public sqlGetNextRow {} {
	variable dbHandle

	return [mysqlnext $dbHandle]
    }

    ####################
    # mysqlmap command #
    ####################

    # ??? what to do with mysqlmap ???

    #####################
    # mysqlseek command #
    #####################

    proc public sqlseek {index} { variable dbHandle; mysqlseek $dbHandle $index }

    ####################
    # mysqlcol command #
    ####################

    # ??? what to do with mysqlcol ???

    #####################
    # mysqlinfo command #
    #####################

    proc public sqldatabases {} {
	variable dbHandle
	return [mysqlinfo $dbHandle databases]
    }

    proc public sqldbname {} {
	variable dbHandle
	return [mysqlinfo $dbHandle dbname?]
    }

    proc public sqlhost {} {
	variable dbHandle
	return [mysqlinfo $dbHandle host?]
    }

    proc public sqltables {} {
	variable dbHandle
	return [mysqlinfo $dbHandle tables]
    }

    #######################
    # mysqlresult command #
    #######################

    proc public sqlResultColumns {} {
	variable dbHandle
	return [mysqlresult $dbHandle cols?]
    }

    proc public sqlResultCurPos {} {
	variable dbHandle
	return [mysqlresult $dbHandle current?]
    }

    proc public sqlResultNumRows {} {
	variable dbHandle
	return [mysqlresult $dbHandle rows?]
    }

    ######################
    # mysqlstate command #
    ######################

    proc public sqlDbState {}  {
	variable dbHandle
	return [mysqlstate $dbHandle]
    }


    ####################
    # Utility commands #
    ####################

    proc public safeSqlString {s} {
	regsub -all "\"" $s {&&} s
	return $s
    }
}


