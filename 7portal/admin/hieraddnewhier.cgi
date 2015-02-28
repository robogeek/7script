#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>
<head>
<{

  package require tree 1.0

  ::tree::initCGI

  set scriptName [::7cgi::getScriptName]
  set pathInfo   [::7cgi::getPathInfo]

  set hierId [lindex [cgi get hierId] 0]
  set newNodeName        [lindex [cgi get newNodeName] 0]
  set newNodeDescription [lindex [cgi get newNodeDescription] 0]
  set addAction          [lindex [cgi get addAction] 0]

  regsub {hieraddnewhier.cgi} $scriptName {hiertree.cgi} treeScript
  regsub {hieraddnewhier.cgi} $scriptName {hierhiers.cgi} hiersScript
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
  7script if {$addAction == ""} {

    <p>You have requested to add a new hierarchy node
    within <{ ::tree::getHierarchyDescription $hierId }>.

    <form action="<$scriptName><$pathInfo>" method="post">
    <input type="hidden" name="hierId" value="<$hierId>">
    <table>
    <tr><th align="right">Name: </th>
        <td><{ ::tree::getHierarchyDescription $hierId }>
            <input type="text" name="newNodeName"></td>
    </tr>
    <tr><th align="right">Description: </th>
        <td><input type="text" name="newNodeDescription"></td>
    </tr>
    <tr><th align="center" colspan="2">
        <input type="submit" name="addAction" value="Create">
        <input type="submit" name="addAction" value="Cancel" onClick="reloadFrames();">
        </th>
    </table>
    </form>
  } elseif {$addAction == "Cancel"} {
    <script>
     reloadFrames();
    </script>
  } elseif {$addAction == "Create"} {
    <{
      7script if [catch {
           ::tree::addSubCategory $hierId $newNodeName $newNodeDescription
          } errorString] {
        <b>ERROR</b>: Cannot add category <$newNodeName> because:
        <br><$errorString>
      } else {
        <script>
         reloadFrames();
        </script>
      }
    }>
  }
}>
</body>
</html>
