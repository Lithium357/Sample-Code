# Tcl 8.6 core TclOO. Run: tclsh snapshot_events.tcl
# Synchronous event delivery to command PREFIXES, not scripts. Prefixes and
# event values are expanded as Tcl list words; no eval/string concatenation.
# Registration order is delivery order. A dispatch snapshots the registrations:
# on/off during a callback affects the NEXT event. First callback error stops
# that dispatch and keeps its Tcl error options. Nested emit is rejected.
# Callbacks must not destroy this hub or yield. No asynchronous delivery claim.
package require Tcl 8.6

oo::class create EventHub {
    variable handlers nextId busy
    constructor {} { set handlers {}; set nextId 0; set busy 0 }
    method on {prefix} {
        if {[catch {llength $prefix} size] || $size == 0} {
            return -code error -errorcode {HUB PREFIX} "nonempty command prefix required"
        }
        # Command lookup is deliberately deferred to emit: aliases/commands can
        # change after registration. This is not a command-allowlist sandbox.
        set id $nextId
        incr nextId
        dict set handlers $id $prefix
        return $id
    }
    method off {id} {
        if {![dict exists $handlers $id]} {
            return -code error -errorcode {HUB TOKEN} "unknown subscription"
        }
        dict unset handlers $id
    }
    method size {} { return [dict size $handlers] }
    method emit {event value} {
        if {$busy} {
            return -code error -errorcode {HUB BUSY} "nested emit is not permitted"
        }
        set snapshot $handlers
        set busy 1
        try {
            set results {}
            dict for {id prefix} $snapshot {
                lappend results [{*}$prefix $event $value]
            }
            return $results
        } finally {
            set busy 0
        }
    }
}

proc equal {actual expected label} {
    if {$actual ne $expected} { error "$label: expected <$expected>, got <$actual>" }
}
proc expectError {script code} {
    set status [catch {uplevel 1 $script} result options]
    equal $status 1 "must raise error"
    equal [dict get $options -errorcode] $code "error code"
    return [list $result $options]
}
proc {receiver with space} {tag event value} { return [list $tag $event $value] }

set hub [EventHub new]
try {
    equal [$hub emit empty ""] {} "empty dispatch"
    equal [$hub size] 0 "initial size"
    expectError {$hub on {}} {HUB PREFIX}
    expectError {$hub on "\{"} {HUB PREFIX}
    equal [$hub size] 0 "invalid prefixes preserve registrations"
    set id [$hub on [list {receiver with space} {tag ; [not a script]}]]
    set data {spaces ; set ::injected yes; [also-not-code] $variable \ tail}
    equal [$hub emit {event ; literal} $data] \
        [list [list {tag ; [not a script]} {event ; literal} $data]] "literal words"
    equal [info exists ::injected] 0 "no script injection"
    equal [$hub emit "" ""] [list [list {tag ; [not a script]} "" ""] "empty values"
    $hub off $id
    expectError {$hub off $id} {HUB TOKEN}
    equal [$hub emit after 0] {} "unsubscribed handler"
} finally { $hub destroy }

# Independent fixed trace, not an expected result generated through emit.
set trace {}
set changed 0
proc recorder {name event value} { lappend ::trace $name; return $name }
proc mutator {hub event value} {
    lappend ::trace A
    if {!$::changed} {
        set ::changed 1
        $hub off $::second
        $hub on [list recorder C]
    }
    return A
}
set hub [EventHub new]
try {
    $hub on [list mutator $hub]
    set second [$hub on [list recorder B]]
    equal [$hub emit tick 1] {A B} "snapshot preserves removed handler"
    equal [$hub size] 2 "one removed, one added"
    equal [$hub emit tick 2] {A C} "next snapshot sees edits"
    equal $trace {A B A C} "delivery trace"
} finally { $hub destroy }

proc decline {event value} {
    return -code error -errorcode {FIXTURE DECLINED} -errorinfo fixture-stack \
        "declined: $value"
}
set hub [EventHub new]
try {
    set trace {}
    $hub on [list recorder before]
    set failed [$hub on decline]
    $hub on [list recorder after]
    lassign [expectError {$hub emit test {literal value}} {FIXTURE DECLINED}] message options
    equal $message {declined: literal value} "original error message"
    equal [string match {fixture-stack*} [dict get $options -errorinfo]] 1 "error info retained"
    equal $trace before "first error stops dispatch"
    $hub off $failed
    equal [$hub emit next 0] {before after} "busy restored after callback failure"
} finally { $hub destroy }

proc nested {hub event value} { $hub emit inner $value }
set hub [EventHub new]
try {
    set token [$hub on [list nested $hub]]
    expectError {$hub emit outer 1} {HUB BUSY}
    $hub off $token
    equal [$hub emit recovered 2] {} "busy restored after recursion rejection"
    set token [$hub on [list ::missingFixtureCommand]]
    expectError {$hub emit missing 3} {TCL LOOKUP COMMAND ::missingFixtureCommand}
    $hub off $token
    equal [$hub emit recovered 4] {} "busy restored after command lookup failure"
} finally { $hub destroy }
puts "snapshot events: literal prefixes, snapshots, errors and busy recovery passed"
