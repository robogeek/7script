# site.tcl - User implementation for 7portal, used by a site to coordinate
#   core facilities of their site.


package provide site 1.0

package require 7portal 1.0

namespace eval ::site {

    # Initialize the back end core software modules
    ::7portal::init

    # Initialize the database characteristics
    ::7portal::setSqlDbHost     ""
    ::7portal::setSqlDbUser     "root"
    ::7portal::setSqlDbPassword "--changeme--"
    ::7portal::setSqlDbName     "bdh"

    # Suck in & re-export all the methods from 7portal.
    namespace import ::7portal::*
    foreach e [::7portal::exports] {
	namespace export $e
    }

    proc init {} {
    }

    proc openDb {} {
	::7portal::sqlOpenDb
    }
}
