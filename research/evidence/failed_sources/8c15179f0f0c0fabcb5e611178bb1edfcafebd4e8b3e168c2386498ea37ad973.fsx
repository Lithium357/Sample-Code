// F# 8 syntax, .NET SDK FSI, no NuGet/services. Run:
// dotnet fsi --langversion:8.0 --exec applicative_panel.fsx
// Synchronous applicative validation: and! accumulates independent errors in
// field order; let! gates dependent checks. It does not schedule parallel work
// or catch arbitrary exceptions. Units of measure distinguish length and area.
// Wire grammar: 1..5 ASCII integer digits, optional dot and 1..3 fractional
// digits. No sign, whitespace, exponent, grouping or Unicode digits. Leading
// zeros are allowed. Width/height 1..10000 mm; optional coat 0..1000 mm, and
// coat cannot exceed half the shorter side. None is absent; Some "" is invalid.
open System
open System.Globalization
open System.Text.RegularExpressions

[<Measure>] type mm
type Issue = { Field: string; Code: string }
type Validation<'T> = Valid of 'T | Invalid of Issue list
let invalid field code = Invalid [{ Field = field; Code = code }]
let map f source = match source with Valid value -> Valid(f value) | Invalid errors -> Invalid errors

type ValidationBuilder() =
    member _.Return(value) = Valid value
    member _.ReturnFrom(source: Validation<'T>) = source
    member _.Bind(source, continuation) =
        match source with Valid value -> continuation value | Invalid errors -> Invalid errors
    member _.BindReturn(source, mapping) = map mapping source
    member _.MergeSources(left, right) =
        match left, right with
        | Valid a, Valid b -> Valid(a, b)
        | Invalid a, Invalid b -> Invalid(a @ b)
        | Invalid errors, _ | _, Invalid errors -> Invalid errors
let validation = ValidationBuilder()

let shape = Regex(@"\A[0-9]{1,5}(?:\.[0-9]{1,3})?\z", RegexOptions.CultureInvariant)
let parseLength field low high (raw: string) : Validation<decimal<mm>> =
    if isNull raw || not (shape.IsMatch raw) then invalid field "syntax"
    else
        match Decimal.TryParse(raw, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture) with
        | true, number ->
            let measured = number * 1M<mm>
            if measured < low || measured > high then invalid field "range"
            else Valid measured
        | _ -> invalid field "syntax"

let parseCoat raw =
    match raw with
    | None -> Valid None
    | Some text -> parseLength "coat" 0M<mm> 1000M<mm> text |> map Some

type Panel = { Width: decimal<mm>; Height: decimal<mm>; Coat: decimal<mm> option; Area: decimal<mm^2> }
let geometry width height coat =
    match coat with
    | Some amount when amount > min width height / 2M -> invalid "coat" "geometry"
    | _ -> Valid ()

let validatePanel width height coat = validation {
    let! w = parseLength "width" 1M<mm> 10000M<mm> width
    and! h = parseLength "height" 1M<mm> 10000M<mm> height
    and! c = parseCoat coat
    let! () = geometry w h c
    return { Width = w; Height = h; Coat = c; Area = w * h }
}

let mutable checks = 0
let check condition label =
    if not condition then failwith ("failed: " + label)
    checks <- checks + 1
let issue field code = { Field = field; Code = code }

let savedCulture = CultureInfo.CurrentCulture
try
    CultureInfo.CurrentCulture <- CultureInfo.GetCultureInfo "fr-FR"
    check (parseLength "sample" 1M<mm> 10000M<mm> "1.25" = Valid 1.25M<mm>) "culture independent"
finally
    CultureInfo.CurrentCulture <- savedCulture

// Literal expected records/error lists, independent of parser implementation.
let panelFixtures = [
    "10", "6", Some "3", Valid { Width = 10M<mm>; Height = 6M<mm>; Coat = Some 3M<mm>; Area = 60M<mm^2> }, "measured result"
    "10", "6", Some "3.001", Invalid [issue "coat" "geometry"], "dependent geometry"
    "bad", "0", Some "bad", Invalid [issue "width" "syntax"; issue "height" "range"; issue "coat" "syntax"], "all field errors in order"
    null, null, Some null, Invalid [issue "width" "syntax"; issue "height" "syntax"; issue "coat" "syntax"], "null fields accumulate"
    "1", "1", Some "", Invalid [issue "coat" "syntax"], "empty is not absent"
    "1", "10000", None, Valid { Width = 1M<mm>; Height = 10000M<mm>; Coat = None; Area = 10000M<mm^2> }, "width height boundaries"
    "10000", "10000", Some "1000", Valid { Width = 10000M<mm>; Height = 10000M<mm>; Coat = Some 1000M<mm>; Area = 100000000M<mm^2> }, "upper bounds"
    "1", "1", Some "0", Valid { Width = 1M<mm>; Height = 1M<mm>; Coat = Some 0M<mm>; Area = 1M<mm^2> }, "explicit zero coat"
]
for w, h, c, expected, label in panelFixtures do
    check (validatePanel w h c = expected) label

let visited = ResizeArray<string>()
let source label result = visited.Add label; result
let mutable dependentCalls = 0
let accumulated : Validation<int> = validation {
    let! a = source "a" (invalid "a" "broken")
    and! b = source "b" (invalid "b" "broken")
    and! c = source "c" (Valid 3)
    let! total = (dependentCalls <- dependentCalls + 1; Valid(a + b + c))
    return total
}
check (accumulated = Invalid [issue "a" "broken"; issue "b" "broken"]) "generic accumulation"
check (visited |> Seq.sort |> Seq.toList = ["a"; "b"; "c"]) "independent sources exactly once"
check (dependentCalls = 0) "dependent stage gated"
let bound = validation { let! value = Valid 7 in return value + 1 }
check (bound = Valid 8) "successful bind return"
let carried : Validation<int> = validation { return! Invalid [issue "x" "carried"] }
check (carried = Invalid [issue "x" "carried"]) "return from"
let boom = InvalidOperationException("owned fixture exception")
let mutable caught = false
try
    let result : Validation<int> = validation {
        let! value = Valid 1
        return (if value = 1 then raise boom else value)
    }
    ignore result
with error -> caught <- Object.ReferenceEquals(error, boom)
check caught "arbitrary exception identity preserved"

// Independent lexical and scaled-integer oracle: no regex, TryParse or builder.
let reference field low high (raw: string) : Validation<decimal<mm>> =
    let digitString (s: string) minimum maximum =
        s.Length >= minimum && s.Length <= maximum && Seq.forall (fun c -> c >= '0' && c <= '9') s
    if isNull raw then invalid field "syntax"
    else
        let parts = raw.Split('.')
        let lexical =
            match parts with
            | [|whole|] -> digitString whole 1 5
            | [|whole; fraction|] -> digitString whole 1 5 && digitString fraction 1 3
            | _ -> false
        if not lexical then invalid field "syntax"
        else
            let digits s = Seq.fold (fun n c -> n * 10L + int64 (int c - int '0')) 0L s
            let whole = digits parts[0]
            let fraction = if parts.Length = 1 then 0L else digits (parts[1].PadRight(3, '0'))
            let scaled = whole * 1000L + fraction
            if scaled < low || scaled > high then invalid field "range"
            else Valid(decimal scaled / 1000M * 1M<mm>)

let literals = [null; ""; "0"; "0.999"; "00001"; "10000"; "10000.000"; "10000.001";
                "1000.001"; "99999"; "000001"; "1.0000"; ".5"; "1."; " 1"; "1\n";
                "+1"; "-1"; "1,25"; "1e2"; "١"; "１２"; "\u00a01"; "NaN"; "Infinity"]
let generated = [ for whole in ["0"; "00001"; "1"; "9"; "999"; "1000"; "10000"; "99999"; "123456"] do
                      for tail in [""; ".0"; ".001"; ".999"; ".0000"; "."; ".x"] do yield whole + tail ]
let previousCulture = CultureInfo.CurrentCulture
try
    for culture in ["en-US"; "fr-FR"; "ar-SA"] do
        CultureInfo.CurrentCulture <- CultureInfo.GetCultureInfo culture
        check (parseLength "sample" 1M<mm> 10000M<mm> "1.25" = Valid 1.25M<mm>) "culture independent"
        for low, high in [1000L, 10000000L; 0L, 1000000L] do
            for raw in literals @ generated do
                let actual = parseLength "sample" (decimal low / 1000M * 1M<mm>) (decimal high / 1000M * 1M<mm>) raw
                check (actual = reference "sample" low high raw) "independent grammar and scaled oracle"
finally
    CultureInfo.CurrentCulture <- previousCulture
printfn "applicative panel: %d checks passed" checks
