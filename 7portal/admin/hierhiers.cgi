#!/home/david/.7script/bin/7script -7script_subst
<HTML><!-- -*- html -*- -->
<{

  package require tree 1.0

  ::tree::initCGI

  set hierId     [::tree::getHierId]
  set sql        [::7portal::get7SqlHandle]
  set sqlHandle  [${sql}::getSqlDbHandle]
  set tbnmItems  [::tree::getTbnameItems]
  set tbnmHier   [::tree::getTbnameHier]
  set scriptName [::7cgi::getScriptName]
  set pathInfo   [::7cgi::getPathInfo]

  regsub {hierhiers.cgi} $scriptName {hieredithier.cgi} editScript
  regsub {hierhiers.cgi} $scriptName {hierdelhier.cgi}  delScript
  regsub {hierhiers.cgi} $scriptName {hiermovehier.cgi} moveScript
  regsub {hierhiers.cgi} $scriptName {hieraddnewhier.cgi} addNewScript

  set nodes [::tree::getChildNodes $hierId]
  set itemInfo ""
  foreach item $nodes {
    set id [lindex $item 0]
    ${sql}::sqlselect "SELECT id,name,url,description FROM $tbnmHier WHERE id=$id"
    mysqlmap $sqlHandle {id name url description} {
	    lappend itemInfo [list $id $name $url $description]
    }
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
<div align="center">
<h1>Hierarchy nodes under 
  <{
    set i 0
    7script foreach item [::tree::findHierPath $hierId] {
      <{ 7script if {$i > 0} { : } }>
      <b><{ incr i; lindex $item 1 }></b>
    }
  }>
</h1>
<table>
  <tr>
    <td>
      <form action="<$addNewScript><$pathInfo>" method="post">
      <input type="submit" name="action" value="Add new node">
      <input type="hidden" name="hierId" value="<$hierId>">
      </form>
    </td>
    <td>
      <form action="<$editScript><$pathInfo>" method="post">
      <input type="submit" name="action" value="Edit this node">
      <input type="hidden" name="itemId" value="<$hierId>">
      <input type="hidden" name="hierId" value="<$hierId>">
      </form>
    </td>
  </tr>
</table>
</div>
<table border="1">
<{
  7script foreach item $itemInfo {
    <tr>
    <{
      set id   [lindex $item 0]
      set name [lindex $item 1]
      set url  [lindex $item 2]
      set desc [lindex $item 3]
      return ""
    }>
    <td><b><$name></b> (<i><tt><$url></tt></i>): <$desc></td>
    <td>
    <form action="<$editScript><$pathInfo>" method="post">
    <input type="submit" name="action" value="Edit">
    <input type="hidden" name="itemId" value="<$id>">
    <input type="hidden" name="hierId" value="<$hierId>">
    </form>
    </td>
    <td>
    <form action="<$delScript><$pathInfo>" method="post">
    <input type="submit" name="action" value="Delete">
    <input type="hidden" name="itemId" value="<$id>">
    <input type="hidden" name="hierId" value="<$hierId>">
    </form>
    </td>
    <td>
    <form action="<$moveScript><$pathInfo>" method="post">
    <input type="submit" name="action" value="Move">
    <input type="hidden" name="itemId" value="<$id>">
    <input type="hidden" name="sourceHierId" value="<$id>">
    <input type="hidden" name="hierId" value="<$hierId>">
    </form>
    </td>
    </tr>
  }
}>
</table>
</body>
</html>
