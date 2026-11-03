# Tcl 8.6+, no Tk/UI or packages. Run: tclsh versioned_patch.tcl.
# A copy-on-write dictionary patch with compare-and-swap version checking.
# State is created by newState; applyPatch returns a new state or throws.
# Empty patches do not increment the version. Names/values are data, never eval.
namespace eval store {
    proc newState {} { return [dict create version 0 data {}] }
    proc fail {kind message} {
        return -code error -errorcode [list TRAIN PATCH $kind] $message
    }
    proc validVersion {text} {
        set n [string length $text]
        expr {$n >= 1 && $n <= 9 && [string trim $text 0123456789] eq "" &&
              ($n == 1 || [string index $text 0] ne "0")}
    }
    proc validKey {text} {
        expr {[string length $text] >= 1 && [string length $text] <= 32}
    }
    proc applyPatch {state expected edits} {
        if {![validVersion $expected]} { fail VERSION "canonical version required" }
        if {$expected ne [dict get $state version]} { fail STALE "version changed" }
        if {[catch {llength $edits} count]} { fail FORMAT "patch must be a list" }
        if {$count > 16} { fail LIMIT "at most sixteen edits" }
        if {$count == 0} { return $state }
        if {$expected eq "999999999"} { fail LIMIT "version exhausted" }
        set pending [dict get $state data]
        foreach edit $edits {
            if {[catch {llength $edit} width] || $width == 0} {
                fail FORMAT "edit must be a nonempty list"
            }
            set op [lindex $edit 0]
            set key [lindex $edit 1]
            if {![validKey $key]} { fail KEY "key length outside 1..32" }
            switch -exact -- $op {
                put {
                    if {$width != 3} { fail FORMAT "put key value" }
                    set value [lindex $edit 2]
                    if {[string length $value] > 256} { fail LIMIT "value too long" }
                    dict set pending $key $value
                }
                delete {
                    if {$width != 2} { fail FORMAT "delete key" }
                    if {![dict exists $pending $key]} { fail MISSING "missing source" }
                    dict unset pending $key
                }
                rename {
                    if {$width != 3} { fail FORMAT "rename source destination" }
                    set destination [lindex $edit 2]
                    if {![validKey $destination]} { fail KEY "invalid destination" }
                    if {![dict exists $pending $key]} { fail MISSING "missing source" }
                    if {[dict exists $pending $destination]} { fail EXISTS "destination exists" }
                    dict set pending $destination [dict get $pending $key]
                    dict unset pending $key
                }
                default { fail OP "unsupported edit" }
            }
        }
        return [dict create version [expr {$expected + 1}] data $pending]
    }
}
proc check {truth} { if {!$truth} { error "assertion failed" } }
proc reject {command kind} {
    set code [catch {uplevel 1 $command} message options]
    check [expr {$code == 1}]
    check [expr {[dict get $options -errorcode] eq [list TRAIN PATCH $kind]}]
}

set initial [store::newState]
check [expr {[store::applyPatch $initial 0 {}] eq $initial}]
set literal {[error injected]; $env(HOME) \backslash}
set binary "a\u0000b"
set edits [list [list put {space key} $literal] [list put binary $binary]]
set first [store::applyPatch $initial 0 $edits]
check [expr {[dict get $first version] == 1 && [dict size [dict get $first data]] == 2}]
check [expr {[dict get $first data {space key}] eq $literal}]
check [expr {[dict get $first data binary] eq $binary}]
check [expr {[dict get $initial version] == 0 && [dict size [dict get $initial data]] == 0}]
set second [store::applyPatch $first 1 [list [list rename {space key} {new key}] [list delete binary]]]
check [expr {[dict get $second version] == 2 && [dict size [dict get $second data]] == 1}]
check [expr {[dict get $second data {new key}] eq $literal}]
check [expr {[dict exists $first data binary] && [dict exists $first data {space key}]}]
reject [list store::applyPatch $first 0 {}] STALE
foreach bad {{} 00 01 -1 +1 a 1.0 {1 } 1000000000} {
    reject [list store::applyPatch $initial $bad {}] VERSION
}
reject [list store::applyPatch $initial "1\n" {}] VERSION
set malformed "\{"
reject [list store::applyPatch $initial 0 $malformed] FORMAT
reject [list store::applyPatch $initial 0 [list $malformed]] FORMAT
reject [list store::applyPatch $initial 0 [list {}]] FORMAT
reject [list store::applyPatch $initial 0 [list [list put x]]] FORMAT
reject [list store::applyPatch $initial 0 [list [list put {} value]]] KEY
reject [list store::applyPatch $initial 0 [list [list put [string repeat x 33] value]]] KEY
reject [list store::applyPatch $initial 0 [list [list put x [string repeat v 257]]]] LIMIT
reject [list store::applyPatch $initial 0 [list [list delete absent]]] MISSING
reject [list store::applyPatch $first 1 [list [list rename binary {space key}]]] EXISTS
reject [list store::applyPatch $initial 0 [list [list explode x]]] OP

# A valid prefix followed by failure must not publish prefix state.
set saved $first
reject [list store::applyPatch $first 1 [list [list put staged yes] [list delete missing]]] MISSING
check [expr {$first eq $saved && ![dict exists $first data staged]}]
set sixteen [lrepeat 16 [list put same value]]
set full [store::applyPatch $initial 0 $sixteen]
check [expr {[dict get $full version] == 1 && [dict size [dict get $full data]] == 1}]
reject [list store::applyPatch $initial 0 [lrepeat 17 [list put same value]]] LIMIT
set largestKey [string repeat k 32]
set emptyValue [store::applyPatch $initial 0 [list [list put x {}]]]
check [expr {[dict exists $emptyValue data x] && [dict get $emptyValue data x] eq ""}]
set largestValue [string repeat v 256]
set boundary [store::applyPatch $initial 0 [list [list put $largestKey $largestValue]]]
check [expr {[dict get $boundary data $largestKey] eq $largestValue}]
set exhausted [dict create version 999999999 data {}]
check [expr {[store::applyPatch $exhausted 999999999 {}] eq $exhausted}]
reject [list store::applyPatch $exhausted 999999999 [list [list put x y]]] LIMIT
set result "Tcl patches: copy-on-write state, exact error codes, CAS, quoting, NUL data and rollback invariants passed"
puts $result
set result
