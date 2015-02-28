
package provide 7util 1.0

namespace eval ::7util {

    #
    # ::7util::attrValSafify - Make a value safe to include in an HTML
    #      attribute value.  The rule in the HTML spec is that
    #
    # *) Attribute values are where you have:  <TAG attr="value">
    # *) The value should be (especially with the coming XHTML requiring
    #   that you do so) be quoted.
    # *) Quoting:  Use double quotes
    # *) To enclose a double quote, use character entities:  &quot; or &#34;
    #
    proc attrValSafify {val} {
	regsub -all -- \" $val {&quot;} newVal
	return $newVal
    }
    namespace export attrValSafify

    #
    # about - Provide an information table showing the CGI invocation
    #   environment (environment variables and CGI values)
    #
    7script template about {} {
	<table border=3 width="100%">
	<caption><B>CGI Arguments</B></caption>
	<tr><th width="50%" bgcolor=grey>Argument</th>
	<th width="50%" bgcolor=grey>Value</th></tr>
	<{
	    7script foreach arg [cgi args] {
		<tr><th align=right><$arg></th>
		<td><{
		    set vl [cgi get $arg]
		    7script if {[llength $vl] > 1} {
			<ul><{ 7script foreach val $vl {<li><$val>} }></ul>
		    } else {<{
			lindex $vl 0
		    }>}
		}></td></tr>
	    }
	}>
	</table>
	<hr>
	<table border=3 width="100%">
	<caption><B>Environment variables</B></caption>
	<tr><th width="50%" bgcolor=grey>Env Variable</th>
	<th width="50%" bgcolor=grey>Value</th></tr>
	<{
	    7script foreach envar [array names env ] {
		<tr><th align=right><$envar></th><td><$env($envar)></td></tr>
	    }
	}>
	</table>
    }
    namespace export about

    proc exports {} { return [namespace export] }
}
