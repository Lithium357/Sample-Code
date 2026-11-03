// F# 8-compatible syntax, .NET SDK 10 F# Interactive; no NuGet packages.
// dotnet fsi --langversion:8.0 --exec stock_transitions.fsx
// Immutable inventory transaction: validate/apply all deltas, or return an error
// without publishing a partial map. This is single-process data, not a DB lock.
// Precondition: initial map has uppercase 1..8-letter keys and stock 0..1000.
open System
open System.Globalization

[<Measure>] type item
type Inventory = Map<string, int<item>>
type Problem =
    | Malformed of index: int
    | OutsideRange of index: int * sku: string
    | TooMany

// Partial active pattern: lexical shape and canonical integer spelling are
// checked separately from stock invariants. No leading +, -0 or leading zeros.
let (|StockDelta|_|) (line: string) =
    if isNull line then None
    else
        match line.Split(':') with
        | [|sku; text|] when sku.Length >= 1 && sku.Length <= 8 &&
                            (sku |> Seq.forall (fun c -> c >= 'A' && c <= 'Z')) ->
            match Int32.TryParse(text, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture) with
            | true, amount when amount >= -999 && amount <= 999 && string amount = text ->
                Some(sku, amount * 1<item>)
            | _ -> None
        | _ -> None

let applyBatch (initial: Inventory) (lines: string list) : Result<Inventory, Problem> =
    if lines.Length > 16 then Error TooMany
    else
        let rec apply index pending state =
            match pending with
            | [] -> Ok state
            | line :: tail ->
                match line with
                | StockDelta(sku, delta) ->
                    let previous = state |> Map.tryFind sku |> Option.defaultValue 0<item>
                    let next = previous + delta
                    if next < 0<item> || next > 1000<item> then Error(OutsideRange(index, sku))
                    else apply (index+1) tail (state |> Map.add sku next)
                | _ -> Error(Malformed index)
        apply 0 lines initial

let check truth = if not truth then failwith "assertion failed"
let initial: Inventory = Map.ofList ["PEN", 4<item>; "INK", 1<item>]
check (applyBatch initial [] = Ok initial)
let expected = Map.ofList ["PEN", 2<item>; "INK", 1<item>; "PAPER", 3<item>]
check (applyBatch initial ["PEN:-2"; "PAPER:3"] = Ok expected)
check (initial = Map.ofList ["PEN",4<item>; "INK",1<item>])
check (applyBatch initial ["PEN:3"; "INK:-2"] = Error(OutsideRange(1,"INK")))
check (applyBatch initial ["PEN:3"; "bad"] = Error(Malformed 1))
check (initial.["PEN"] = 4<item>)
check (applyBatch Map.empty ["X:999"; "X:1"] = Ok(Map.ofList ["X",1000<item>]))
check (applyBatch Map.empty ["X:999"; "X:2"] = Error(OutsideRange(1,"X")))
check (applyBatch initial ["INK:-1"] = Ok(initial |> Map.add "INK" 0<item>))
check (applyBatch Map.empty ["ABSENT:-1"] = Error(OutsideRange(0,"ABSENT")))
check (applyBatch initial (List.replicate 16 "PEN:0") = Ok initial)
check (applyBatch initial (List.replicate 17 "PEN:0") = Error TooMany)
for bad in [null; ""; "x:1"; ":1"; "ABCDEFGHI:1"; "X:01"; "X:+1"; "X:-0";
            "X: 1"; "X:1 "; "X:1:2"; "X:1000"; "X:-1000"; "X:2147483648"] do
    check (applyBatch initial [bad] = Error(Malformed 0))

// Independent one-key reference: scan every prefix as integer arithmetic.
// Comparing only the final total would miss a temporary negative balance.
for starting in 0..8 do
    for a in -4..4 do
        for b in -4..4 do
            let stock = Map.ofList ["X", starting * 1<item>]
            let result = applyBatch stock [sprintf "X:%d" a; sprintf "X:%d" b]
            if starting+a < 0 then check (result = Error(OutsideRange(0,"X")))
            elif starting+a+b < 0 then check (result = Error(OutsideRange(1,"X")))
            else check (result = Ok(Map.ofList ["X", (starting+a+b)*1<item>]))
            check (stock.["X"] = starting * 1<item>)
printfn "F# transitions: active patterns, units of measure, immutable maps, indexed failures and 729 prefix-reference cases passed"
