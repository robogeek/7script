# snhtdoc.tcl - HTML wrapper classes for 7Script -*- tcl -*-

package provide ht 1.0

namespace eval ht {


    namespace export href

}

7script template ht::href {url text {anchor ""}} {
 <A href="<$url><{ 7script if {$anchor != ""} {#<$anchor>} }>"><$text></a>
}

7script template ht::bold {text} {<b><$text></b>}
7script template ht::big  {text} {<big><$text></big>}
7script template ht::italic {text} {<i><$text></i>}
7script template ht::strike {text} {<strike><$text></strike>}
7script template ht::small  {text} {<small><$text></small>}
7script template ht::subscript {text} {<sub><$text></sub>}
7script template ht::superscript {text} {<sup><$text></sup>}
7script template ht::typewriter {text} {<tt><$text></tt>}
7script template ht::underline {text} {<u><$text></u>}
7script template ht::blink {text} {<blink><$text></blink>}
7script template ht::h1 {text} {<h1><$text></h1>}
7script template ht::h2 {text} {<h2><$text></h2>}
7script template ht::h3 {text} {<h3><$text></h3>}
7script template ht::h4 {text} {<h4><$text></h4>}
7script template ht::h5 {text} {<h5><$text></h5>}
7script template ht::h6 {text} {<h6><$text></h6>}

7script template ht::font {text size color {face ""}} {
    <{
	7script if {$face != ""} {<font color="<$color>" size="<$size>" face="<$face>">} \
	    else {<font color="<$color>" size="<$size>">}
    }><$text></font>
}

proc ht::img {url align alt width height} {
    set ret "<img src=\"$url\" "
    if {$align != ""} { append ret "align=\"$align\" " }
    if {$alt   != ""} { append ret "alt=\"$alt\" "     }
    if {$width != ""} { append ret "width=\"$width\" " }
    if {$height != ""} { append ret "height=\"$height\" " }
    append ret ">"
    return $ret
}

