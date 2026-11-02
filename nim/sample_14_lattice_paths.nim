# Lattice paths.
# Nim 2.x; nim c -r FILE.nim
# Contract: Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.
# Run this file independently; failures exit nonzero.

proc lattice_paths(v_width_arg: int64, v_height_arg: int64): int64 =
    var v_width = v_width_arg
    var v_height = v_height_arg
    var v_index: int64 = 0
    var v_result: int64 = 0
    var v_steps: int64 = 0
    v_steps = (v_width + v_height)
    v_result = 1
    v_index = 1
    while v_index <= v_width:
        v_result = ((v_result * ((v_steps - v_width) + v_index)) div v_index)
        v_index = (v_index + 1)
    return v_result

when isMainModule:
    doAssert lattice_paths(0, 0) == 1, "lattice_paths fixture 1: (0, 0) -> 1"
    doAssert lattice_paths(2, 2) == 6, "lattice_paths fixture 2: (2, 2) -> 6"
    doAssert lattice_paths(3, 2) == 10, "lattice_paths fixture 3: (3, 2) -> 10"
    doAssert lattice_paths(4, 4) == 70, "lattice_paths fixture 4: (4, 4) -> 70"
    echo "lattice_paths: 4 fixtures passed"
