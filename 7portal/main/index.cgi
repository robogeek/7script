#!/home/david/.7script/bin/7script -7script_subst
<HTML><!-- -*- html -*- -->
<{

# This is a sample index.cgi.  We'll probably have one
# for each node in the directory.

  package require tree 1.0

  ::tree::initCGI

  set scriptName [::tree::getScriptName]
  set hierId     [::tree::getHierId]
  set pathInfo   [::tree::getPathInfo]

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
<{ ::tree::getMetaTags }>
<{ ::tree::getHeaderTitle }>
<!-- TBD: What other header info is needed? -->
</head>
<{ ::tree::getBODY }>

<div align="center">
    <{ ::tree::getMainLogo }>
    <{ ::tree::getPageTitle }>
    <{ ::tree::getMainToolbar }>
    <{ ::tree::getSiteSearchForm }>
</div>

<!-- TBD: suggested books etc -->
<!-- TBD: separate page for all books etc related to this hier -->
<!-- TBD: Advertising banner area -->

<{ ::tree::getHierarchyNavigator }>

<hr>
<!-- Hierarchy -->
<p>
<{ ::tree::getChildHierarchyNavigator }>
<hr>
<!-- links -->
<p>
<{ ::tree::getLinksNavigator }>

<!-- This is the footer.  Includes some navigation -->
<{ ::tree::getSecondaryToolbar }>
<a href="/about">About BeDoHave.COM</a> | <a href="/advertise">Advertising</a>
<!-- TBD: Editors -->

</body>
</html>
