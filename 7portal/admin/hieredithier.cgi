#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>
<head>
<{

  package require tree 1.0

  ::tree::initCGI

  set sql        [::tree::getDbHandle]
  set sqlHandle  [${sql}::getDbHandle]
  set tbnmHier   [::tree::getTbnameHier]
  set pathInfo   [::7cgi::getPathInfo]
  set scriptName [::7cgi::getScriptName]
  set editAction        [lindex [cgi get editAction] 0]
  # In this case, itemId is the hierId for the hier node
  # being editted
  set hierId            [lindex [cgi get hierId]     0]
  set itemId            [lindex [cgi get itemId]     0]
  set itemName          [lindex [cgi get itemName]   0]
  set itemDescription   [lindex [cgi get itemDescription] 0]

  regsub {hieredithier.cgi} $scriptName {hiertree.cgi} treeScript
  regsub {hieredithier.cgi} $scriptName {hierhiers.cgi} hiersScript
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
  7script if {$editAction == ""} {
    <{
      # Get info from the hier node $itemId into
      # itemName, and itemDescription
      ${sql}::sqlselect "SELECT name,description FROM $tbnmHier WHERE id=$itemId"
      mysqlmap $sqlHandle {itemName itemDescription} { }
      return ""
    }>
    <p>Editing the information for <{ ::tree::getHierarchyDescription $itemId }>
    <form action="<$scriptName><$pathInfo>" method="post">
    <input type="hidden" name="itemId" value="<$itemId>">
    <input type="hidden" name="hierId" value="<$hierId>">
    <table>
    <tr><th align="right">Name: </th>
        <td><input type="text" name="itemName" value="<{ cgi encode $itemName }>"></td>
    </tr>
    <tr><th align="right">Description: </th>
        <td><input type="text" name="itemDescription" value="<{ cgi encode $itemDescription }>"></td>
    </tr>
    <tr><th colspan="2">
        <input type="submit" name="editAction" value="Proceed">
        <input type="submit" name="editAction" value="Cancel">
        <input type="reset">
        </th>
    </tr>
    </table>
    </form>
  } elseif {$editAction == "Proceed"} {
    <{
      7script if [catch {
             ::tree::changeHierInfo $itemId $itemName $itemDescription
         } errorString] {
        <b>ERROR</b>: Cannot edit category <$itemName> because:
        <br><$errorString>
      } else {
        <script>
         reloadFrames();
        </script>
      }
    }>
  } elseif {$editAction == "Cancel"} {
    <script>
     reloadFrames();
    </script>
  }
}>

</body>
</html>
