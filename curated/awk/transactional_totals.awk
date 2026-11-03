# GNU AWK 4+ (arrays of arrays, asorti comparator), not POSIX awk.
# LC_ALL=C gawk -f transactional_totals.awk; BEGIN runs local fixtures and exits.
# Chunks are LF-separated zone<TAB>quantity records; blank lines are ignored.
# Canonical ASCII quantities 0..1000000, <=16 zones, <=1000 total records.
# Failed chunks leave aggregate state unchanged and return line/kind diagnostics.
# State starts empty and is thereafter produced only by successful applyRecords.
function reject(diagnostic, line, kind) {
    diagnostic["line"] = line
    diagnostic["kind"] = kind
    return 0
}
function applyRecords(text, state, diagnostic,    pending, lines, fields, k, count, i, zone, raw, quantity, rows) {
    delete diagnostic
    if (text == "") return 1
    rows = 0
    for (k in state) {
        pending[k]["total"] = state[k]["total"]
        pending[k]["rows"] = state[k]["rows"]
        rows += state[k]["rows"]
    }
    count = split(text, lines, "\n")
    for (i = 1; i <= count; i++) {
        if (lines[i] == "") continue
        if (split(lines[i], fields, "\t") != 2) return reject(diagnostic, i, "FIELDS")
        zone = fields[1]; raw = fields[2]
        if (zone !~ /^[a-z]{1,12}$/) return reject(diagnostic, i, "ZONE")
        if (raw !~ /^(0|[1-9][0-9]{0,6})$/) return reject(diagnostic, i, "VALUE")
        quantity = raw + 0
        if (quantity > 1000000) return reject(diagnostic, i, "VALUE")
        if (rows == 1000) return reject(diagnostic, i, "ROWS")
        if (!(zone in pending)) {
            if (length(pending) == 16) return reject(diagnostic, i, "ZONES")
            pending[zone]["total"] = 0
            pending[zone]["rows"] = 0
        }
        pending[zone]["total"] += quantity
        pending[zone]["rows"]++
        rows++
    }
    delete state
    for (k in pending) {
        state[k]["total"] = pending[k]["total"]
        state[k]["rows"] = pending[k]["rows"]
    }
    return 1
}
function byTotal(a, av, b, bv) {
    if (av != bv) return av > bv ? -1 : 1
    return a < b ? -1 : (a != b)
}
function summary(state,    totals, indices, k, n, i, output) {
    for (k in state) totals[k] = state[k]["total"]
    n = asorti(totals, indices, "byTotal")
    output = ""
    for (i = 1; i <= n; i++) {
        k = indices[i]
        output = output sprintf("%s:%.0f/%.0f;", k, state[k]["total"], state[k]["rows"])
    }
    return output
}
function check(truth, label) {
    if (!truth) { print "assertion failed: " label > "/dev/stderr"; exit 1 }
}
BEGIN {
    delete state; delete diagnostic
    check(applyRecords("", state, diagnostic) && length(state) == 0, "empty chunk")
    check(applyRecords("west\t2\nnorth\t4\nwest\t3\nsouth\t5\n", state, diagnostic), "first chunk")
    check(summary(state) == "south:5/1;west:5/2;north:4/1;", "numeric descending and tie order")
    check(applyRecords("east\t0\nnorth\t1\n", state, diagnostic), "second chunk")
    check(summary(state) == "north:5/2;south:5/1;west:5/2;east:0/1;", "merge and zero")
    before = summary(state)
    check(!applyRecords("staged\t1\nbad\t-1", state, diagnostic), "bad suffix")
    check(diagnostic["line"] == 2 && diagnostic["kind"] == "VALUE", "failure position/type")
    check(summary(state) == before && !("staged" in state), "whole chunk rollback")
    malformed[1] = "north\t01"; malformed[2] = "north\t1000001"
    malformed[3] = "north\t1\textra"; malformed[4] = "Upper\t1"
    malformed[5] = "north\t1\r"; malformed[6] = "north\t"
    kinds[1] = "VALUE"; kinds[2] = "VALUE"; kinds[3] = "FIELDS"
    kinds[4] = "ZONE"; kinds[5] = "VALUE"; kinds[6] = "VALUE"
    for (i = 1; i <= 6; i++) {
        check(!applyRecords(malformed[i], state, diagnostic), "malformed input")
        check(diagnostic["line"] == 1 && diagnostic["kind"] == kinds[i], "exact diagnostic")
        check(summary(state) == before, "state after rejection")
    }
    check(applyRecords("\n\n", state, diagnostic) && length(diagnostic) == 0, "blank chunk resets diagnostics")
    check(summary(state) == before, "blank chunk preserves totals")
    delete many
    for (i = 0; i < 16; i++) check(applyRecords(sprintf("a%c\t0", 97+i), many, diagnostic), "zone capacity")
    check(length(many) == 16, "sixteen zones")
    check(!applyRecords("aq\t0", many, diagnostic) && diagnostic["kind"] == "ZONES", "seventeenth zone")
    check(length(many) == 16 && !("aq" in many), "zone limit preserves state")
    delete maximum
    text = ""
    for (i = 0; i < 1000; i++) text = text "same\t1000000\n"
    check(applyRecords(text, maximum, diagnostic), "exact row and quantity bounds")
    check(maximum["same"]["total"] == 1000000000 && maximum["same"]["rows"] == 1000, "exact integer total")
    check(!applyRecords("same\t0", maximum, diagnostic) && diagnostic["kind"] == "ROWS", "row budget includes zero quantities")
    check(maximum["same"]["rows"] == 1000 && maximum["same"]["total"] == 1000000000, "row limit atomicity")
    print "GNU AWK totals: nested arrays, deterministic numeric sorting, rollback, exact diagnostics and bounded integer arithmetic passed"
    exit 0
}
