#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>
<head>
<{

  package require tree 1.0

  ::tree::initCGI

  set sql        [::7portal::get7SqlHandle]
  set sqlHandle  [${sql}::getSqlDbHandle]
  set tbnmItems  [::tree::getTbnameItems]
  set pathInfo   [::7cgi::getPathInfo]
  set scriptName [::7cgi::getScriptName]
  set editAction        [lindex [cgi get editAction] 0]
  # In this case, itemId is the hierId for the hier node
  # being editted
  set itemId            [lindex [cgi get itemId]     0]

  regsub {itemedit.cgi}    $scriptName {itemtree.cgi}          treeScript
  regsub {itemedit.cgi.*$} $scriptName {iteminstructions.html} instructionsScript
  return ""
}>
<script>
function reloadFrames() {
  parent.items.location = "<$treeScript><$pathInfo>";
  parent.editor.location = "<$instructionsScript>";
}
</script>
<title></title>
</head>
<body bgcolor="white">

<{
  7script if {$editAction == ""} {
    <{
      ${sql}::sqlselect "SELECT name,url,description,icon,type FROM $tbnmItems WHERE id=$itemId"
      mysqlmap ${sqlHandle} { itemName itemUrl itemDescription itemIcon itemType } {
      }
      return ""
    }>
    <p>
    <form action="<$scriptName><$pathInfo>" method="post">
    <input type="hidden" name="itemId"   value="<$itemId>">
    <input type="hidden" name="itemType" value="<$itemType>">
    <table>
    <tr>
      <th align="right">Name: </th>
      <td>
        <input type="text" name="itemName" value="<$itemName>" size="60">
      </td>
    </tr>
    <tr>
      <th align="right">Description: </th>
      <td>
        <input type="text" name="itemDescription" value="<$itemDescription>" size="60">
      </td>
    </tr>
    <tr>
      <th align="right">URL: </th>
      <td>
        <input type="text" name="itemUrl" value="<$itemUrl>" size="60">
      </td>
    </tr>
    <tr>
      <th align="right">Icon: </th>
      <td>
        <input type="text" name="itemIcon" value="<$itemIcon>" size="60">
      </td>
    </tr>
    <tr>
      <th align="center" colspan="2">
        <input type="submit" name="editAction" value="Proceed">
        <input type="reset">
        <input type="submit" name="editAction" value="Cancel">
      </th>
    </tr>
    </table>
    </form>
  } elseif {$editAction == "Cancel"} {
    <script>
     reloadFrames();
    </script>
  } elseif {$editAction == "Proceed"} {
    <{
      ::tree::changeSomeItemInfo $itemId \
              [lindex [cgi get itemName       ] 0] \
              [lindex [cgi get itemType       ] 0] \
              [lindex [cgi get itemDescription] 0] \
              [lindex [cgi get itemUrl        ] 0] \
              [lindex [cgi get itemIcon       ] 0]
      return ""
    }>
    <script>
     reloadFrames();
    </script>
  }
}>

</body>
</html>
