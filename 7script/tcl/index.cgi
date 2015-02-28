#!/home/david/.7script/bin/7script -7script_subst
<HTML><!-- -*- html -*- -->
<{

# This is a sample index.cgi.  We'll probably have one
# for each node in the directory.

  package require 7tree

  set 7t [::7tree::new]
  #${7t}::7tree

  ${7t}::openDb
  ${7t}::initHier

  return ""
}>
<head>
<{ ${7t}::getMetaTags }>
<{ ${7t}::getHeaderTitle }>
<!-- TBD: What other header info is needed? -->
</head>
<{ ${7t}::getBODY }>


<div align="center">
    <{ ${7t}::getMainLogo }>
    <{ ${7t}::getPageTitle }>
    <{ ${7t}::getMainToolbar }>
    <{ ${7t}::getSiteSearchForm }>
</div>

<!-- TBD: suggested books etc -->
<!-- TBD: separate page for all books etc related to this hier -->
<!-- TBD: Advertising banner area -->

    <{ ${7t}::getHierarchyNavigator }>

    <hr>
    <!-- Hierarchy -->
    <p>
    <{ ${7t}::getChildHierarchyNavigator }>
    <hr>
    <!-- links -->
    <p>
    <{ ${7t}::getLinksNavigator }>


    <!-- This is the footer.  Includes some navigation -->
    <{ ${7t}::getSecondaryToolbar }>
    <a href="/about">About BeDoHave.COM</a>
    <a href="/advertise">Advertising</a>
<!-- TBD: Editors -->

<hr>
<h1>The following is for debugging</h1>
<table border=3 width="100%">
<caption><B>CGI Arguments</B></caption>
<tr><th width="50%" bgcolor=grey>Argument</th>
    <th width="50%" bgcolor=grey>Value</th></tr>
<{
    7script foreach arg [cgi args] {
        <tr><th align=right><$arg></th>
            <td><{
              set vl [cgi get $arg]
              7script if {[llength $vl] > 1} {
                <ul><{ 7script foreach val $vl {<li><$val>} }></ul>
              } else {
                <{ lindex $vl 0 }>
              }
            }></td></tr>
    }
}>
</table>
<hr>
<table border=3 width="100%">
<caption><B>Environment variables</B></caption>
<tr><th width="50%" bgcolor=grey>Env Variable</th>
    <th width="50%" bgcolor=grey>Value</th></tr>
<{
    7script foreach envar [array names env ] {
        <tr><th align=right><$envar></th>
            <td><$env($envar)></td></tr>
    }
}>
</table>


</body>
</html>
