# 7members.tcl - Base package to manage membership.

package provide 7members 1.0

package require 7portal 1.0
package require 7tree 1.0

class ::7members {

    proc public 7members {} {
	variable sql
    }


    ######################
    # 7Tree/ DB ACCESS   #
    ######################

    variable public scalar sql ""        ;# The ::7sql handle to the database
    variable public scalar sqlHandle ""  ;# The mysqltcl handle
    variable public scalar 7t ""         ;# The handle for ::7tree

    #
    # set7tree - Set the handle for ::7tree
    #
    proc public set7tree {_7t} {
	variable 7t
	variable sql
	variable sqlHandle
	set 7t $_7t
	set _sql ${7t}::getDbHandle
	set sqlHandle [${sql}::getSqlDbHandle]
    }

    #####################
    # 7Tree table names #
    #####################

    # XXX Are these needed??  Or should we force the code in 7tree.tcl
    #    to offer proper methods?
    #
    #    variable public scalar tbnmHier ""        ;# The table name for the hierarchy table.
    #    variable public scalar tbnmHierGlue ""    ;# The table name for the hierarchy 'glue' table.
    #    variable public scalar tbnmHierCustom ""  ;# The table name for the hierarchy 'customization' table.
    #    variable public scalar tbnmGlue ""        ;# The table name for the glue table.
    #    variable public scalar tbnmItems ""       ;# Table name for the items table.

    ##########
    # SCHEMA #
    ##########

    proc public createDatabaseSchema {} {
	variable sql

	${sql}::sqlexec [concat {
	    CREATE TABLE } $tbnmMembers {(
		id           INT NOT NULL AUTO_INCREMENT,

		nameFirst    char(64) NOT NULL,
		nameMiddle   char(64),
		nameLast     char(64) NOT NULL,
		emailAddr    char(256) NOT NULL,
		password     char(32) NOT NULL,

		PRIMARY KEY(id),
		INDEX byName(nameFirst,nameMiddle,nameLast),
		INDEX byEmail(emailAddr)
		);
	    }]

	${sql}::sqlexec [concat {
	    CREATE TABLE } $tbnmDemog {(
		memberId        INT NOT NULL,

		PRIMARY KEY(memberId),

		);
	    }]

	${sql}::sqlexec [concat {
	    CREATE TABLE } $tbnmMemberPrefs {(
		memberId        INT NOT NULL,

		PRIMARY KEY(memberId),

		);
	    }]

	${sql}::sqlexec [concat {
	    CREATE TABLE } $tbnmInterests {(
		id           INT NOT NULL AUTO_INCREMENT,

		name         char(64) NOT NULL,
		desc         char(255) NOT NULL,
		url          char(255) NOT NULL,

		PRIMARY KEY(id)
		);
	    }]

	${sql}::sqlexec [concat {
	    CREATE TABLE } $tbnmInterestGlue {(
		memberId           INT NOT NULL,
		interestId         INT NOT NULL,

		PRIMARY KEY(memberId, interestId)
		);
	    }]

    }

}
