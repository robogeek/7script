#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>
<head>
<{

  package require tree 1.0

  ::tree::initCGI

  set sql        [::7portal::get7SqlHandle]
  set sqlHandle  [${sql}::getSqlDbHandle]
  set pathInfo   [::7cgi::getPathInfo]
  set scriptName [::7cgi::getScriptName]
  set editAction        [lindex [cgi get editAction] 0]
  # In this case, itemId is the hierId for the hier node
  # being editted
  set itemId            [lindex [cgi get itemId]     0]

  regsub {itemhiers.cgi}    $scriptName {itemtree.cgi}          treeScript
  regsub {itemhiers.cgi.*$} $scriptName {iteminstructions.html} instructionsScript
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
    <table width="100%">
    <tr><td colspan="2" align="center">
      <{ ::tree::makeItemLink $itemId }>
      <form action="<$scriptName>" method="post">
      <input type="hidden" name="itemId" value="<$itemId>">
      <input type="submit" name="editAction" value="Add Hierarchy">
      </form>
    </td></tr>
    <{
      7script foreach hier [::tree::getHiersForItem $itemId] {
        <tr>
          <td align="right">
            <form action="<$scriptName>" method="post">
            <input type="hidden" name="itemId" value="<$itemId>">
            <input type="hidden" name="hierId" value="<$hier>">
            <input type="submit" name="editAction" value="Remove">
            </form>
          </td>
          <td><{ ::tree::getHierarchyDescription $hier }></td>
        </tr>
      }
    }>
    </table>
  } elseif {$editAction == "Cancel"} {
    <{
      set itemId [lindex [cgi get itemId] 0]
      return ""
    }>
    <script>
     location = "<$scriptName>?itemId=<$itemId>";
    </script>
  } elseif {$editAction == "Remove"} {
    <{
      set itemId [lindex [cgi get itemId] 0]
      set hierId [lindex [cgi get hierId] 0]
      ::tree::deleteItemFromCategory $hierId $itemId
      return ""
    }>
    <script>
     location = "<$scriptName>?itemId=<$itemId>";
    </script>
  } elseif {$editAction == "Add Hierarchy"} {
    <{
      set itemId [lindex [cgi get itemId] 0]
      set hierId [lindex [cgi get hierId] 0]
      if {$hierId == "" || $hierId == "-1"} { set hierId 1 }
      return ""
    }>
    <p>
    Adding this item to new hierarchy node.  You need to
    select the hierarchy node, and the current node selected
    is below.
    <p>
    <form action="<$scriptName>" method="post">
    <input type="hidden" name="itemId" value="<$itemId>">
    <input type="submit" name="editAction" value="Cancel">
    </form>
    <table border="1">
    <tr>
      <th align="right">Item</th>
      <td><{ ::tree::makeItemLink $itemId }></td>
    </tr>
    <tr>
      <th align="right">Current new hierarchy</th>
      <td>
        <{ ::tree::getHierarchyDescription $hierId }>
        <form action="<$scriptName>" method="post">
        <input type="hidden" name="itemId" value="<$itemId>">
        <input type="hidden" name="hierId" value="<$hierId>">
        <input type="submit" name="editAction" value="Add To This Hierarchy">
        </form>
      </td>
    </tr>
    <tr>
      <th align="right">Select deeper hierarchy</th>
      <td>
        <form action="<$scriptName>" method="post">
        <input type="hidden" name="itemId" value="<$itemId>">
        <{ ::tree::makeChildNodeSelector $hierId "hierId" }>
        <input type="submit" name="editAction" value="Add Hierarchy">
        </form>
      </td>
    </tr>
    </table>
  } elseif {$editAction == "Add To This Hierarchy"} {
    <{
      set itemId [lindex [cgi get itemId] 0]
      set hierId [lindex [cgi get hierId] 0]
      ::tree::addItemToHier $hierId $itemId
      return ""
    }>
    <script>
     location = "<$scriptName>?itemId=<$itemId>";
    </script>
  }
}>
</body>
</html>
