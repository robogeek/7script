#!/home/david/.7script/bin/7script -7script_subst
<HTML><!-- -*- html -*- -->
<{

  package require tree

  ::tree::initCGI

  set sql        [::7portal::get7SqlHandle]
  set sqlHandle  [${sql}::getSqlDbHandle]
  set tbnmItems  [::tree::getTbnameItems]
  set scriptName [::7cgi::getScriptName]
  set pathInfo   [::7cgi::getPathInfo]

  regsub {itemtree.cgi} $scriptName {itemcustom.cgi} customScript
  regsub {itemtree.cgi} $scriptName {itemowner.cgi}  ownerScript
  regsub {itemtree.cgi} $scriptName {itemedit.cgi}   editScript
  regsub {itemtree.cgi} $scriptName {itemhiers.cgi}  hiersScript

  proc getItemInfo {pattern} {
    global tbnmItems
    global sql
    global sqlHandle

    ${sql}::sqlselect "SELECT id,name,url FROM $tbnmItems WHERE name LIKE \"$pattern\" ORDER BY name"
    set items ""
    mysqlmap ${sqlHandle} { id name url } {
      lappend items [list $name $url $id]
    }
    return $items
  }

  7script template formatItem {item} {<{
      global customScript
      global ownerScript
      global editScript
      global hiersScript
      return ""
      }><dt><a href="<{ lindex $item 1 }>" target="_blank">
          <b><{ lindex $item 0 }></b></a>
         <dd>[
            <a href="<$customScript>?itemId=<{ lindex $item 2 }>" target="editor">
              <i>Customization</i></a> |
            <a href="<$editScript>?itemId=<{ lindex $item 2 }>" target="editor">
              <i>Edit Item</i></a> |
            <a href="<$hiersScript>?itemId=<{ lindex $item 2 }>" target="editor">
              <i>Hierarchy Membership</i></a> |
            <a href="<$ownerScript>?itemId=<{ lindex $item 2 }>" target="editor">
              <i>Item ownership</i></a> ]}


  return ""
}>
<head>
</head>
<body bgcolor="white">

<form action="<$scriptName><$pathInfo>" method="post">
<select name="chooseLetter" size="1">
<option value="A">A
<option value="B">B
<option value="C">C
<option value="D">D
<option value="E">E
<option value="F">F
<option value="G">G
<option value="H">H
<option value="I">I
<option value="J">J
<option value="K">K
<option value="L">L
<option value="M">M
<option value="N">N
<option value="O">O
<option value="P">P
<option value="Q">Q
<option value="R">R
<option value="S">S
<option value="T">T
<option value="U">U
<option value="V">V
<option value="W">W
<option value="X">X
<option value="Y">Y
<option value="Z">Z
</select>
<input type="submit" name="treeAction" value="GO">
</form>

<form action="<$scriptName><$pathInfo>" method="post">
Search: <input type="text" name="treeSearchVal"><input type="submit" name="treeAction" value="Search">
</form>

<{
  7script switch -regexp -- [lindex [cgi get treeAction] 0] {
  {^$} {
    <!-- Nothing to do -->
  }
  {^GO$} {
    <dl><{
      set chooseLetter [lindex [cgi get chooseLetter] 0]
      7script foreach item [getItemInfo "$chooseLetter%"] {
        <{ formatItem $item }>
      }
    }></dl>
  }
  {^Search$} {
    <dl><{
      set phrase [lindex [cgi get treeSearchVal] 0]
      7script foreach item [getItemInfo "%$phrase%"] {
        <{ formatItem $item }>
      }
    }></dl>
  }
  }
}>


</body>
</html>
