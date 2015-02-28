#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>
<head>
<{

  package require tree 1.0

  ::tree::initCGI

  set tbnmHier   [::tree::getTbnameHier]
  set scriptName [::7cgi::getScriptName]
  set pathInfo   [::7cgi::getPathInfo]
  set hierId     [::tree::getHierId]

  set editAction [lindex [cgi get editAction] 0]

  regsub {hieritems.cgi} $scriptName {hiertree.cgi}  treeScript
  regsub {hieritems.cgi} $scriptName {hierhiers.cgi} hiersScript
  return ""
}>
<script>
function reloadFrames() {
  parent.hierarchy.location = "<$treeScript><$pathInfo>";
  parent.editor.location    = "<$scriptName><$pathInfo>";
}
</script>
<title></title>
</head>
<body bgcolor="white">

<{
  7script if {$editAction == ""} {
    <table border="1" width="100%">
    <caption>Items in <{ ::tree::getHierarchyDescription $hierId }></caption>
    <tr><td align="center" colspan="2">
      <form action="<$scriptName><$pathInfo>" method="post">
      <input type="submit" name="editAction" value="Cancel">
      </form>
    </td></tr>
    <{
      7script foreach item [::tree::getItemInfoInHier $hierId "link" ] {
      <tr><{
          set itemId   [lindex $item 0]
          set itemName [lindex $item 1]
          set itemType [lindex $item 2]
          set itemDesc [lindex $item 3]
          set itemUrl  [lindex $item 4]
          set itemIcon [lindex $item 5]
          return ""
      }>
      <td>
        <div align="center">
        <a href="<$itemUrl>" target="_blank"><b><$itemName></b></a> : <$itemDesc>
        </div>
        <form action="<$scriptName><$pathInfo>" method="post">
        <input type="hidden" name="hierId" value="<$hierId>">
        <input type="hidden" name="itemId" value="<$itemId>">
        <input type="hidden" name="itemType" value="<$itemType>">
        <input type="hidden" name="itemIcon" value="<$itemIcon>">
        <table>
        <tr><th align="right">Name: </th>
            <td><input type="text" name="itemName" value="<$itemName>" size="60"></td>
        </tr>
        <tr><th align="right">URL: </th>
            <td><input type="text" name="itemUrl" value="<$itemUrl>" size="60"></td>
        </tr>
        <tr><th align="right">Description: </th>
            <td><input type="text" name="itemDesc" value="<$itemDesc>" size="60"></td>
        </tr>
        <tr><td align="center" colspan="2">
          <input type="submit" name="editAction" value="Change Info">
        </td></tr>
        </table>
        </form>
      </td>
      <td align="center">
        <form action="<$scriptName><$pathInfo>" method="post">
        <input type="hidden" name="itemId" value="<$itemId>">
        <input type="hidden" name="hierId" value="<$hierId>">
        <input type="submit" name="editAction" value="Remove">
        </form>
      <!-- Maybe we want to enable this??                          -->
      <!--  <form action="<$scriptName><$pathInfo>" method="post"> -->
      <!--  <input type="hidden" name="itemId" value="<$itemId>">  -->
      <!--  <input type="hidden" name="hierId" value="<$hierId>">  -->
      <!--  <input type="submit" name="editAction" value="Move">   -->
      <!--  </form>                                                -->
      <!-- Maybe we want to enable this??                          -->
      <!--  <form action="<$scriptName><$pathInfo>" method="post"> -->
      <!--  <input type="hidden" name="itemId" value="<$itemId>">  -->
      <!--  <input type="submit" name="editAction" value="Copy">   -->
      <!--  </form>                                                -->
      </td>
      </tr>
      }
    }>
    </table>
  } elseif {$editAction == "Cancel"} {
    <script>
     reloadFrames();
    </script>
  } elseif {$editAction == "Change Info"} {
    <{
      set itemId   [lindex [cgi get itemId  ] 0]
      set itemType [lindex [cgi get itemType] 0]
      set itemIcon [lindex [cgi get itemIcon] 0]
      set itemName [lindex [cgi get itemName] 0]
      set itemUrl  [lindex [cgi get itemUrl ] 0]
      set itemDesc [lindex [cgi get itemDesc] 0]
      return ""
    }>
    <{ ::tree::changeSomeItemInfo $itemId $itemName $itemType $itemDesc $itemUrl $itemIcon }>
    <script>
     reloadFrames();
    </script>
  } elseif {$editAction == "Remove"} {
    <{
      set itemId   [lindex [cgi get itemId  ] 0]
      set hierId   [lindex [cgi get hierId  ] 0]
      ::tree::deleteItemFromCategory $hierId $itemId
      return ""
    }>
    <script>
     reloadFrames();
    </script>
  } elseif {$editAction == "Move"} {
    <script>
     reloadFrames();
    </script>
  } elseif {$editAction == "Copy"} {
    <script>
     reloadFrames();
    </script>
  }
}>

</body>
</html>
