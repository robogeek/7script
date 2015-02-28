#!/home/david/.7script/bin/7script -7script_subst
<HTML><!-- -*- html -*- -->
<{

  package require tree 1.0

  ::tree::initCGI

  set scriptName [::7cgi::getScriptName]
  set pathInfo   [::7cgi::getPathInfo]
  set hierId     [::tree::getHierId]

  regsub {hiertree.cgi} $scriptName {hiercustom.cgi}  customScript
  regsub {hiertree.cgi} $scriptName {hiereditors.cgi} editorsScript
  regsub {hiertree.cgi} $scriptName {hieritems.cgi}   itemsScript
  regsub {hiertree.cgi} $scriptName {hierhiers.cgi}   hiersScript

  7script template formatItem {id name url} {<{
	      global scriptName
	      global customScript
	      global editorsScript
	      global itemsScript
	      global hiersScript
	      return ""
     }><a href="<$scriptName><$url>"><b><$name></b></a>
	      <br>[ <a href="<$customScript><$url>" target="editor">
		  <i>Customization</i></a> | 
	      <a href="<$editorsScript><$url>" target="editor">
		  <i>Editors</i></a> | 
	      <a href="<$itemsScript><$url>" target="editor">
		  <i>Items</i></a> | 
	      <a href="<$hiersScript><$url>" target="editor">
		  <i>Hierarchy</i></a> ]
  }
  return ""
}>
<head>
<{
  7script if {$hierId == ""} {
    <script>
    location = "<$scriptName><{ ::tree::findExistingParentHier $env(PATH_INFO) }>";
    </script>
  }
}>
</head>
<body bgcolor="white">
<{ formatItem 1 "TOP" "/" }>
<ul>
<{
  proc formatList {l} {
    return [7script foreach item $l {
      <{
        7script if { [llength $item] > 1 } {
          <{
	      set data [lindex $item 0]
	      set rest [lindex $item 1]
	      set id   [lindex $data 0]
	      set name [lindex $data 1]
	      set url  [lindex $data 2]
              return ""
	  }><li><{ formatItem $id $name $url }>
	        <ul> <{ formatList $rest }> </ul></li>
        } else {
	  <li><{
	    set data [lindex $item 0]
            set id   [lindex $data 0]
            set name [lindex $data 1]
            set url  [lindex $data 2]
	    formatItem $id $name $url
	  }></li>
        }
      }>
    }]
  }
  set list [::tree::makeHierTree [::tree::getHierId]]
  formatList $list
}>
</ul>
</body>
</html>
