# -*- tcl -*-
package require dbw    1.0
package require attrdb 1.0

namespace eval attrdbbrowse {
}

proc attrdbbrowse::action {path action} {

    set handle ""
    if {$path != ""} {
    	if [catch {dbw::new $path "r"} handle] {
	        return [7script body {<P><B>ERROR:</b>
	        Failed to open the database <$path> because <$handle>
            }]
    	}
    }

    set ret ""
    switch -regexp $action {
	{.*Show.*one.*key.*} {
	    set ret [attrdbbrowse::showOneKey $handle [lindex [cgi get key] 0]]
	}
	
	{.*Show.*Keys.*} {
	    set ret [attrdbbrowse::showKeys $handle]
	}

	{.*Show.*Map.*} {
	    set ret [attrdbbrowse::showMap $handle]
	}

	{.*Show.*Buckets.*} {
	    set ret [attrdbbrowse::showBuckets $handle]
    }
    
	{.*Fetch.*Key.*} {
	    set ret [attrdbbrowse::showOneKey $handle [lindex [cgi get FetchKey] 0]]
	}
    }

    if {$handle != ""} {
        dbw::close $handle
    }

    return $ret
}

proc attrdbbrowse::showKeys {handle} {
    set path [cgi encode [dbw::dbname $handle]]
    7script foreach key [lsort -integer [attrdb::keys $handle]] {
        <{ set ekey [cgi encode $key]; return "" }>
        <a href="/attrdbbrowse.cgi?dbasePath=<$path>&action=Show+one+key&key=<$ekey>">
                <$key>
        </a>
    }
}

#7script template attrdbbrowse::showKeys {handle} {
#<table border=1>
#<tr>
#    <th>Key</th>
#    <{ 7script foreach field [attrdb::getFields $handle] {<th><$field></th>} }>
#</tr>
#<{
#    7script foreach key [lsort -integer [attrdb::keys $handle]] {
#    <tr>
#        <td><$key></td>
#        <{
#            7script foreach field [attrdb::getFields $handle] {
#                <td><{ attrdb::getVal $handle $key $field }></td>
#	        }
#	    }>
#    </tr>
#	}
#}>
#</table>
#}

7script template attrdbbrowse::showMap {handle} {
<table border=1>
<tr><th>Name</th>
    <th>CGI var name</th>
    <th>Num CGI expected</th>
    <th>Comparisons</th>
    <th>Bucketizing</th>
</tr>
<{
    7script foreach m [attrdb::getMap $handle] {
      <tr>
        <td align="center"><{ lindex $m 0 }></td>
        <td align="center"><{ lindex $m 1 }></td>
        <td align="center"><{ lindex $m 2 }></td>
        <td align="center"><{ lindex $m 3 }></td>
        <td align="center"><{ lindex $m 4 }></td>
      </tr>
    }
}>
</tr>
</table>
}

7script template attrdbbrowse::showBuckets {handle} {
<table>
<tr>
    <th>Field</th>
    <th>Bucket name</th>
    <th>Items</th>
</tr>
<{
    7script foreach field [attrdb::getFields $handle] {
    <tr>
        <th><$field></th>
        <td>
            <table>
            <{
                if [catch {attrdb::getBuckets $handle $field} buckets] {
                    return ""
                }
                7script foreach bucket $buckets {
                <tr>
                    <td><$bucket></td>
                    <td>
                        <ul>
                        <{
                            7script foreach item [dbw::fetch $handle $bucket] {
                            <li>
                                <{
                                    set key [lindex $item 0]
                               	    set path [cgi encode [dbw::dbname $handle]]
                               	    set ekey [cgi encode $key]
                                    return ""
                                }>
                                <a href="/attrdbbrowse.cgi?dbasePath=<$path>&action=Show+one+key&key=<$ekey>">
                                            <$key>
                                </a>
                                <{ lindex $item 1 }>
                             }
                         }>
                         </ul>
                     </td>
                 </tr>
                 }
             }>
             </table>
        </td>
    </tr>
    }
}>
</table>
}

7script template attrdbbrowse::showOneKey {handle key} {
<table border=1>
<{
    7script foreach field [attrdb::getFields $handle] {
    <tr>
        <th><$field></th>
        <td><{ attrdb::getVal $handle $key $field }></td>
    </tr>
    }
}>
</table>
}

#<tr>
#    <th>Key</th>
#    <{ 7script foreach field [attrdb::getFields $handle] {<th><$field></th>} }>
#</tr>
#<tr>
#    <td><$key></td>
#    <{
#        7script foreach field [attrdb::getFields $handle] {
#            <td><{ attrdb::getVal $handle $key $field }></td>
#        }
#    }>
#</tr>
#</table>
#}

7script template attrdbbrowse::fetchValue {handle key} {
    <table border=1>
    <tr><th>Key</th><th>Value</th></tr>
    <tr>
    <td><$key></td>
    <td><{ dbw::fetch $handle $key }></td>
    </tr>
    </table>
}
