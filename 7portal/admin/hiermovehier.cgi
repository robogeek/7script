#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>
<head>
<{

  package require tree 1.0

  set sql        [::tree::getDbHandle]
  set tbnmHier   [::tree::getTbnameHier]
  set sqlHandle  [${sql}::getDbHandle]
  set pathInfo   [::7cgi::getPathInfo]
  set scriptName [::7cgi::getScriptName]
  set hierId     [::tree::getHierId]

  set sourceHierId [lindex [cgi get sourceHierId] 0]
  set destHierId   [lindex [cgi get destHierId  ] 0]
  set moveAction   [lindex [cgi get moveAction  ] 0]

  regsub {hiermovehier.cgi} $scriptName {hiertree.cgi} treeScript
  regsub {hiermovehier.cgi} $scriptName {hierhiers.cgi} hiersScript

  7script template formatItem {id name url} {<{
	      global scriptName
	      global pathInfo
              global sourceHierId
              global 7t
	      return ""
     }>
       <tr>
         <td>
         <form action="<$scriptName><$pathInfo>" method="post">
         <input type="submit" name="moveAction" value="Move here">
         <input type="hidden" name="sourceHierId" value="<$sourceHierId>">
         <input type="hidden" name="destHierId" value="<$id>">
         </form>
         </td>
         <td>
         <a href="<$scriptName><$url>?sourceHierId=<$sourceHierId>">
         <{ ::tree::getHierarchyDescription $id }>
         </a>
         </td>
       </tr>}

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
	  }><{ formatItem $id $name $url }><{ formatList $rest }>
        } else {
	  <{
	    set data [lindex $item 0]
            set id   [lindex $data 0]
            set name [lindex $data 1]
            set url  [lindex $data 2]
	    formatItem $id $name $url
	  }>
        }
      }>
    }]
  }

  return ""
}>
<script>
function reloadFrames() {
  parent.hierarchy.location = "<$treeScript><$pathInfo>";
  parent.editor.location    = "<$hiersScript><$pathInfo>";
}
</script>
<title></title>
</head>
<body bgcolor="white">

<{
  7script if {$moveAction == ""} {
    <p>Moving everything under <{ ::tree::getHierarchyDescription $sourceHierId }>.
    <p>Current destination is  <{ ::tree::getHierarchyDescription $hierId }>.

    <form action="<$scriptName><$pathInfo>" method="post">
    <input type="submit" name="moveAction" value="Cancel">
    </form>
    <table border="1">
    <{ formatItem 1 "TOP" "/" }>
    <{
      set list [::tree::makeHierTree $hierId]
      formatList $list
    }>
    </table>
  } elseif {$moveAction == "Cancel"} {
    <script>
     reloadFrames();
    </script>
  } elseif {$moveAction == "Move here"} {


    Moving  <{ ::tree::getHierarchyDescription $sourceHierId }> to <{ ::tree::getHierarchyDescription $destHierId }>.
    <{
      ::tree::moveHierarchy $sourceHierId $destHierId
      7script body {
        <script>
         reloadFrames();
        </script>
      }
    }>
  }
}>

</body>
</html>
