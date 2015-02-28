#!/home/david/.7script/bin/7script -7script_subst
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN"><!-- -*- html -*- -->
<html>

<head>
<{

  package require tree 1.0

  ::tree::initCGI

  set sql        [::tree::getDbHandle]
  set tbnmHier   [::tree::getTbnameHier]
  set tbnmItems  [::tree::getTbnameItems]
  set sqlHandle  [${sql}::getDbHandle]
  set pathInfo   [::7cgi::getPathInfo]
  set scriptName [::7cgi::getScriptName]

  set itemId [lindex [cgi get itemId] 0]
  set hierId [lindex [cgi get hierId] 0]
  set delAction          [lindex [cgi get delAction] 0]

  regsub {hierdelhier.cgi} $scriptName {hierdelyeshier.cgi} delYesScript

  regsub {hierdelhier.cgi} $scriptName {hiertree.cgi} treeScript
  regsub {hierdelhier.cgi} $scriptName {hierhiers.cgi} hiersScript

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
  7script if {$delAction == ""} {
    <p>You have requested to delete <{ ::tree::getHierarchyDescription $itemId }>.
    Doing this will delete the following information.
    If you do not wish to do this, simply use your browsers <b>back</b>
    button to return to the previous screen.
    <form action="<$scriptName><$pathInfo>" method="post">
    <input type="submit" name="delAction" value="Proceed">
    <input type="submit" name="delAction" value="Cancel">
    <input type="hidden" name="itemId" value="<$itemId>">
    <input type="hidden" name="hierId" value="<$hierId>">
    </form>
    
    <ul><{
      set hierList [::tree::getAllChildNodes $itemId]
      set cmd ""
      append cmd "SELECT id,url,name,description " \
         "FROM $tbnmHier WHERE id=$itemId"
      ${sql}::sqlselect $cmd
      mysqlmap $sqlHandle { id url name description } {
        lappend hierList [list $id $url $name $description]
      }
      7script foreach child $hierList {
        <li><{
          set id   [lindex $child 0]
          set url  [lindex $child 1]
          set name [lindex $child 2]
          set desc [lindex $child 3]
          return ""
        }><b><$name></b> (<tt><$url></tt>)
        <{
          set items [::tree::getItemsInHier $id "link"]
          7script if {$items != ""} {
            <table border="1">
            <tr><th width="33%">Item name (URL)</th>
                <th width="33%">Description</th>
                <th width="33%">Categories it is in</th></tr>
            <{
              set cmd ""
              append cmd "SELECT id,name,url,description FROM $tbnmItems WHERE "
              set i 0
              foreach id $items {
                if {$i == 0} {
                  append cmd " id=$id"
                } else {
                  append cmd " OR id=$id"
                }
                incr i
              }
              ${sql}::sqlselect $cmd
              set data ""
              mysqlmap ${sqlHandle} { id name url description } {
                lappend data [list $id $name $url $description]
              }
              7script foreach item $data {
                <tr>
                <td width="33%"><{ lindex $item 1 }><br><tt><{ lindex $item 2 }></tt></td>
                <td width="33%"><{ lindex $item 3 }></td>
                <td width="33%"><{
                  set hiers [::tree::getHiersForItem [lindex $item 0]]
                  7script if {$hiers != ""} {
                    <{
                      7script foreach hier $hiers {
                      <br><{ ::tree::getHierarchyDescription $hier }>
                      }
                    }>
                  }
                }></td>
                </tr>
              }
            }>
            </table>
          }
        }>
      }
    }></ul>
  } elseif {$delAction == "Cancel"} {
    <script>
     reloadFrames();
    </script>
  } elseif {$delAction == "Proceed"} {
    <{
      7script if [catch {
             ::tree::deleteHierarchyTree $itemId
         } errorString] {
        <b>ERROR</b>: Cannot delete category with id <$itemId> because:
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
