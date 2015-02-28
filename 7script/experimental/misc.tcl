#
# doit - Do processing of a template file
#
proc doit {file} {
    set f [open $file "r"]
    set s [read $f]
    close $f
 
    set q [snap_subst $s]
    return $q
}
