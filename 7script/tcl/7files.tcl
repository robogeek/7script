# 7files.tcl - The file is out there - somewhere ;-)
#
# 7files provides a rudimentary file storage capability using
# a table in an SQL database.  It can be used in any SQL database,
# and all it does is add one table to that database.

package provide 7files 1.0

package require 7cgi
package require 7util
package require 7sql

namespace eval ::7files {

    namespace import ::7cgi::*

    #######################
    # DATABASE CONNECTION #
    #######################

    # The actual mysqltcl handle
    variable db
    # The 7sql instance
    variable 7sql

    proc initCGI {} {

	::7cgi::init
	::7files::init7sql
	
	set dbHost     [lindex [cgi get 7filesDbHost    ] 0]
	set dbUser     [lindex [cgi get 7filesDbUser    ] 0]
	set dbPassword [lindex [cgi get 7filesDbPassword] 0]
	set dbName     [lindex [cgi get 7filesDbName    ] 0]

	::7files::setSqlDbHost     $dbHost
	::7files::setSqlDbUser     $dbUser
	::7files::setSqlDbPassword $dbPassword
	::7files::setSqlDbName     $dbName

	::7files::openDatabase
    }

    #
    # use7sql - Use a particular 7sql instance to access the
    #   database.  Unless this method is called, the module will
    #   not function.  The database must have had the 7files table
    #   added for the database to work (see createDatabaseSchema).
    #   Also the 7sql handle must be connected to the MySQL server
    #   and connected to a particular database (using the USE command).
    #
    # @param 7sql The 7sql instance to use.
    #
    proc use7sql {_7sql} {
	variable 7sql
	variable db

	set 7sql $_7sql
	namespace import -force ${7sql}::*
	set db [getSqlDbHandle]
	createDatabaseSchema
    }

    proc init7sql {} {
	variable 7sql
	variable db

	set 7sql [::7sql::new]
	namespace import -force ${7sql}::*
    }

    proc openDatabase {} {
	variable db
	if {[sqlIsOpen] == 0} {
	    sqlOpenDb
	    sqlUseDb
	    createDatabaseSchema
	    set db [getSqlDbHandle]
	}
    }

    ##################
    # USER INTERFACE #
    ##################

    #
    # uiDbLoginInfoForm - A snippet of a form that passes along
    #   the database login information.  This information must
    #   be in every form so that we can log in back to the same
    #   user & database.
    #
    proc uiDbLoginInfoForm {} {
	return [7script body {
	    <input type="hidden" name="7filesDbHost" value="<{::7util::attrValSafify [getSqlDbHost]}>">
	    <input type="hidden" name="7filesDbUser" value="<{::7util::attrValSafify [getSqlDbUser]}>">
	    <input type="hidden" name="7filesDbPassword" value="<{::7util::attrValSafify [getSqlDbPassword]}>">
	    <input type="hidden" name="7filesDbName" value="<{::7util::attrValSafify [getSqlDbName]}>">
	}]
    }

    #
    # uiListFilesForm - Form that displays the "List Files" button.
    #
    proc uiListFilesForm {} {
	return [7script body {
	    <form action="<{::7cgi::getScriptName}>" method="post">
	    <{uiDbLoginInfoForm}>
	    <input type="submit" name="action" value="List files">
	    </form>
	}]
    }

    #
    # ui7FileLister - Show all the 7files files in this database.
    #
    proc ui7FileLister {{prefix ""}} {
	return [7script body {
	<table>
	<tr><th>Commands</th><th>Type</th><th>Name</th><th>Description</th></tr>
	<{
	    variable db
	    set ret ""
	    sqlselect "SELECT fileName, type, description, locked FROM 7files WHERE fileName LIKE '$prefix%'"
	    mysqlmap $db {fileName type desc locked} {
		append ret [7script body {
		    <tr>
		    <td>
		      <form action="<{::7cgi::getScriptName}>" method="post">
		      <{uiDbLoginInfoForm}>
		      <input type="hidden" name="fileName" value="<{
                         ::7util::attrValSafify $fileName
                      }>">
		      <select name="action">
		      <option value="Delete File">Delete File
		      <option value="Edit File">Edit File
		      <{
			  7script if {$locked == "yes"} \
			      {<option name="Unlock File">Unlock File} \
			  else \
			      {<option name="Lock File">Lock File} \
		      }>
		      </select>
		      <input type="submit" name="goober" value="Do it">
		      </form>
		    <td><$type></td>
		    <td><$fileName><{
			7script if {$locked == "yes"} { (<b>LOCKED</b>) }
		    }></td>
		    <td><$desc></td>
		    </tr>
		}]
	    }
	    return $ret
	}>
	</table>
	}]
    }

    #
    # uiNewFile - Form to assist creating a new file.
    #
    proc uiNewFile {} {
	return [7script body {
	    <form action="<{::7cgi::getScriptName}>" method="post">
	    <{uiDbLoginInfoForm}>
	    New file name: <input type="text" name="newFileName" size="60">
	    <br>
	    Description:  <input type="text" name="newFileDesc" size="60">
	    <br>
	    <input type="submit" name="action" value="Create new file">
	    <input type="submit" name="action" value="Cancel">
	    <input type="reset">
	    </form>
	}]
    }

    #
    # uiCreateNewFile - Handles submissions from uiNewFile, creating
    #   the given file.
    #
    proc uiCreateNewFile {} {
	return [7script body {
	<{
	    set fileName [lindex [cgi get newFileName] 0]
	    set desc     [lindex [cgi get newFileDesc] 0]
	    7script if [fileExists $fileName] {
		<b>ERROR: </b> File <$fileName> already exists.
	    } else {<{
		7script if [catch {
		    createFile $fileName "text" $desc
		} msg] {
		    <b>ERROR: </b> <$msg>
		} else {
		    Created <$fileName>.
		}
	    }>}
	}><{uiListFilesForm}>
	}]
    }

    #
    # uiDeleteFile - Delete the chosen file.
    #
    proc uiDeleteFile {} {
	return [7script body {
	<{
	    set fileName [lindex [cgi get fileName] 0]
	    7script if ![fileExists $fileName] {
		<b>ERROR: </b> File <$fileName> does not exist
	    } else {<{
		variable db
		7script if [catch {
		    deleteFile $fileName
		} msg] {
		    <b>ERROR: </b> <$msg>
		} else {
		    File <$fileName> deleted.
		}
	    }>}
	}><{uiListFilesForm}>
	}]
    }

    #
    # uiLockFile - Lock the chosen file.
    #
    proc uiLockFile {} {
	return [7script body {
	<{
	    set fileName [lindex [cgi get fileName] 0]
	    7script if ![fileExists $fileName] {
		<b>ERROR: </b> File <$fileName> does not exist
	    } else {<{
		7script if [catch {
		    lockFile $fileName
		} msg] {
		    <b>ERROR:</b> <$msg>
		} else {
		    File <$fileName> locked.
		}
	    }>}
	}><{uiListFilesForm}>
	}]
    }

    #
    # uiLockFile - Unlock the chosen file.
    #
    proc uiUnlockFile {} {
	return [7script body {
	<{
	    set fileName [lindex [cgi get fileName] 0]
	    7script if ![fileExists $fileName] {
		<b>ERROR: </b> File <$fileName> does not exist
	    } else {<{
		7script if [catch {
		    unlockFile $fileName
		} msg] {
		    <b>ERROR:</b> <$msg>
		} else {
		    File <$fileName> unlocked.
		}
	    }>}
	}><{uiListFilesForm}>
	}]
    }

    #
    # uiFileEditor - Edit the information about the given file
    #
    proc uiEditFile {} {
	return [7script body {
	<{
	    set fileName [lindex [cgi get fileName] 0]
	    set safeFileName [ ::7util::attrValSafify $fileName ]
	    return ""
	}>
	    fileName = <$fileName>
	    safeFileName = <$safeFileName>
	<form action="<{::7cgi::getScriptName}>" method="post">
	<{uiDbLoginInfoForm}>
	<input type="hidden" name="fileName" value="<$safeFileName>">
	<input type="submit" name="action" value="Save changes">
	<input type="submit" name="action" value="Cancel">
	<input type="reset">
	<input type="text" name="fileType" value="<{ getFileType $fileName }>">
	<input type="text" name="fileDescription" value="<{ getFileDescription $fileName }>" size="60">
	<textarea name="textContents" rows="40" cols="70"><{
	    ::7files::getFileContents $fileName
	}></textarea>
	</form>
	}]
    }

    #
    # uiSaveChanges - Save any changes made in uiFileEditor.
    #
    proc uiSaveChanges {} {
	return [7script body {
	<{
	    7script if [catch {
		set fileName     [lindex [cgi get fileName       ] 0]
		set contents     [lindex [cgi get textContents   ] 0]
		set fileType     [lindex [cgi get fileType       ] 0]
		set fileDesc     [lindex [cgi get fileDescription] 0]
		regsub -all "\r" $contents {} contents
		if {[fileExists $fileName] <= 0} {
		    createFile $fileName $fileType $fileDesc
		} else {
		    setFileType        $fileName $fileType
		    setFileDescription $fileName $fileDesc
		}
		setFileContents    $fileName $contents
	    } msg] {
		<b>ERROR: </b> An error occured updating <$fileName>.
		<br><$msg>
	    } else {
		File <$fileName> updated.
	    }
	}><{uiListFilesForm}>
	}]
    }

    ###################
    # UTILITY METHODS #
    ###################

    proc lockFile {fileName} {
	variable db

	set safeFileName [ safeSqlString $fileName ]
	sqlselect "SELECT locked FROM 7files WHERE fileName=\"$safeFileName\""
	mysqlmap $db { locked } { }
	if {$locked != "no"} {
	    error "The file $fileName is already locked - no changes made"
	} else {
	    sqlexec "UPDATE 7files SET locked = \"yes\" WHERE fileName=\"$safeFileName\""
	}
    }
    
    proc unlockFile {fileName} {
	variable db

	set safeFileName [ safeSqlString $fileName ]
	sqlselect "SELECT locked FROM 7files WHERE fileName=\"$safeFileName\""
	mysqlmap $db { locked } { }
	if {$locked != "yes"} {
	    error "The file $fileName is already unlocked - no changes made"
	} else {
	    sqlexec "UPDATE 7files SET locked = \"no\" WHERE fileName=\"$safeFileName\""
	}
    }

    proc getFileContents {fileName} {
	variable db

	if ![fileExists $fileName] {
	    return ""
	}

	set safeFileName [ safeSqlString $fileName ]
	sqlselect "SELECT contents FROM 7files WHERE fileName=\"$safeFileName\""
	mysqlmap $db { contents } { }
	return $contents
    }

    proc setFileContents {fileName contents} {
	set safeFileName [ safeSqlString $fileName ]
	set safeContents [ safeSqlString $contents ]
	sqlexec "UPDATE 7files SET contents=\"$safeContents\" WHERE fileName=\"$safeFileName\""
    }

    proc getFileType {fileName} {
	variable db

	if ![fileExists $fileName] {
	    return ""
	}

	set safeFileName [ safeSqlString $fileName ]
	sqlselect "SELECT type FROM 7files WHERE fileName=\"$safeFileName\""
	mysqlmap $db { type } { }
	return $type
    }

    proc setFileType {fileName type} {
	set safeFileName [ safeSqlString $fileName ]
	set safeType     [ safeSqlString $type ]
	sqlexec "UPDATE 7files SET type=\"$safeType\" WHERE fileName=\"$safeFileName\""
    }

    proc getFileDescription {fileName} {
	variable db

	if ![fileExists $fileName] {
	    return ""
	}

	set safeFileName [ safeSqlString $fileName ]
	sqlselect "SELECT description FROM 7files WHERE fileName=\"$safeFileName\""
	mysqlmap $db { desc } { }
	return $desc
    }

    proc setFileDescription {fileName desc} {
	set safeFileName [ safeSqlString $fileName ]
	set safeDesc     [ safeSqlString $desc ]
	sqlexec "UPDATE 7files SET description=\"$safeDesc\" WHERE fileName=\"$safeFileName\""
    }

    proc deleteFile {fileName} {
	set safeFileName [ safeSqlString $fileName ]
	sqlexec "DELETE FROM 7files WHERE fileName=\"$safeFileName\""
    }

    proc fileExists {fileName} {
	set safeFileName [ safeSqlString $fileName ]
	if [catch {
	    sqlselect "SELECT fileName FROM 7files WHERE fileName = \"$safeFileName\""
	} ret] {
	    return 0
	} else {
	    variable db

	    set count 0
	    mysqlmap $db { fileN } { incr count }
	    if {$count == 0} {
		return 0
	    } else {
		return 1
	    }
	}
	return 0
    }

    proc fileLocked {fileName} {
	set safeFileName [ safeSqlString $fileName ]
	if [catch {
	    sqlselect "SELECT locked FROM 7files WHERE fileName = \"$safeFileName\""
	} ret] {
	    return 0
	} else {
	    variable db

	    set locked "no"
	    mysqlmap $db { locked } { }
	    if {$locked == "yes"} {
		return 1
	    } else {
		return 0
	    }
	}
	return 0
    }

    proc createFile {fileName type desc} {
	set safeFileName [ safeSqlString $fileName ]
	set safeType     [ safeSqlString $type     ]
	set safeDesc     [ safeSqlString $desc     ]
	sqlexec "INSERT INTO 7files VALUES(\"$safeFileName\",\"$safeType\",\"$safeDesc\",\"no\",NULL)"
    }

    ###################
    # Database Schema #
    ###################

    proc createDatabaseSchema {} {
	set t [sqltables]
	if {[lsearch $t "7files"] >= 0} {
	    return 0
	}
	catch {
	    sqlexec {
		DROP TABLE 7files
	    }
	}
	sqlexec {
	    CREATE TABLE 7files (
		fileName     char(255) NOT NULL,
		type         enum('text'),
		description  char(255),
		locked       enum('yes','no'),
		contents     TEXT,

		PRIMARY KEY(fileName)
		)
	}
    }

    ########
    # MISC #
    ########

    # Provide the list of exported functions.
    proc exports {} { return [namespace export] }
}
