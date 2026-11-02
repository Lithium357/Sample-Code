"""Build standalone examples from the executable integer specifications.

The shared algorithms are intentionally parallel across languages. Each emitted
file includes explicit input/output fixtures and its own entry point. This is
an educational generated corpus, not independent real-world project data.
"""
import ast
import hashlib
import importlib.util
import inspect
import json
import os
import shutil
import subprocess
from pathlib import Path
import sys
import textwrap

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / 'python-packages'))
os.environ['TIKTOKEN_CACHE_DIR'] = str(HERE / 'token-cache')
import tiktoken
import algorithms as specs

ROOT = HERE.parent
ENC = tiktoken.get_encoding('cl100k_base')
EXT = {'nim': 'nim', 'cmd': 'cmd', 'assembly': 'asm', 'powershell': 'ps1',
       'bash': 'sh', 'rust': 'rs', 'ruby': 'rb', 'go': 'go', 'php': 'php'}
LABEL = {'nim': 'Nim 2.x; nim c -r FILE.nim',
 'cmd': 'Windows cmd.exe; cmd /d /c FILE.cmd; signed 32-bit arithmetic',
 'assembly': 'x86-64; NASM Intel syntax; Linux ELF64; System V integer argument registers',
 'powershell': 'PowerShell 7; pwsh -NoProfile -File FILE.ps1',
 'bash': 'Bash 4+; bash FILE.sh; integer arithmetic',
 'rust': 'Rust edition 2021; rustc --edition=2021 FILE.rs -o demo; ./demo',
 'ruby': 'Ruby 3.x; ruby FILE.rb', 'go': 'Go 1.20+; go run FILE.go',
 'php': 'PHP 8.x CLI; php FILE.php'}

def tokens(s):
    return len(ENC.encode(s, disallowed_special=()))

def v(name):
    return 'v_' + name

def names(fn):
    params = [a.arg for a in fn.args.args]
    local = sorted({n.id for n in ast.walk(fn) if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Store)} - set(params))
    return params, local

def expr(node, lang):
    if isinstance(node, ast.Constant):
        return str(node.value)
    if isinstance(node, ast.Name):
        prefix = '$' if lang in ('php','powershell') else ''
        return prefix + v(node.id)
    if isinstance(node, ast.UnaryOp):
        assert isinstance(node.op, ast.USub)
        return '(-' + expr(node.operand,lang) + ')'
    if isinstance(node, ast.BinOp):
        a, b = expr(node.left,lang), expr(node.right,lang)
        op = {ast.Add:'+',ast.Sub:'-',ast.Mult:'*',ast.FloorDiv:'/',ast.Mod:'%'}[type(node.op)]
        if isinstance(node.op, ast.FloorDiv):
            if lang == 'ruby':
                return f'({a}).div({b})'
            if lang == 'php':
                return f'intdiv({a}, {b})'
            if lang == 'powershell':
                return f'[long][Math]::Truncate(({a}) / ({b}))'
            if lang == 'nim':
                op = 'div'
        if isinstance(node.op, ast.Mod) and lang in ('nim','powershell'):
            op = 'mod' if lang == 'nim' else '%'
        return f'({a} {op} {b})'
    if isinstance(node, ast.Compare):
        assert len(node.ops) == 1
        op = {ast.Eq:'==',ast.NotEq:'!=',ast.Lt:'<',ast.LtE:'<=',ast.Gt:'>',ast.GtE:'>='}[type(node.ops[0])]
        if lang == 'powershell':
            op = { '==':'-eq','!=':'-ne','<':'-lt','<=':'-le','>':'-gt','>=':'-ge'}[op]
        return f'{expr(node.left,lang)} {op} {expr(node.comparators[0],lang)}'
    raise TypeError(ast.dump(node))

def body(nodes, lang, level=1):
    lines = []
    pad = '    ' * level
    curly = lang in ('php','powershell','go','rust')
    for node in nodes:
        if isinstance(node, ast.Assign):
            left, right = expr(node.targets[0],lang), expr(node.value,lang)
            if lang == 'bash':
                lines.append(pad + f'{left}=$(( {right} ))')
            else:
                lines.append(pad + left + ' = ' + right + (';' if lang in ('php','rust') else ''))
        elif isinstance(node, ast.Return):
            val = expr(node.value,lang)
            if lang == 'bash':
                lines.extend([pad + f'REPLY=$(( {val} ))', pad + 'return 0'])
            else:
                lines.append(pad + 'return ' + val + (';' if lang in ('php','rust') else ''))
        elif isinstance(node, (ast.If,ast.While)):
            keyword = 'if' if isinstance(node,ast.If) else ('for' if lang == 'go' else 'while')
            condition = expr(node.test,lang)
            if lang == 'bash':
                lines.append(pad + f'{keyword} (( {condition} )); ' + ('then' if keyword=='if' else 'do'))
            elif lang == 'nim':
                lines.append(pad + f'{keyword} {condition}:')
            elif curly:
                if lang in ('php','powershell'):
                    condition = '(' + condition + ')'
                lines.append(pad + keyword + ' ' + condition + ' {')
            else:
                lines.append(pad + keyword + ' ' + condition)
            lines.extend(body(node.body,lang,level+1))
            if node.orelse:
                lines.append(pad + ('} else {' if curly else 'else'))
                lines.extend(body(node.orelse,lang,level+1))
            if lang == 'bash':
                lines.append(pad + ('fi' if keyword=='if' else 'done'))
            elif curly:
                lines.append(pad + '}')
            elif lang == 'ruby':
                lines.append(pad + 'end')
        else:
            raise TypeError(ast.dump(node))
    return lines

def render_high(fn, lang, cases, contract):
    name = fn.name
    params, locals_ = names(fn)
    comment = '#' if lang in ('nim','powershell','bash','ruby') else '//'
    lines = [f'{comment} {name.replace("_", " ").capitalize()}.',
             f'{comment} {LABEL[lang]}', f'{comment} Contract: {contract}',
             f'{comment} Run this file independently; failures exit nonzero.']
    if lang == 'php':
        lines = ['<?php', 'declare(strict_types=1);', *lines]
    elif lang == 'bash':
        lines = ['#!/usr/bin/env bash', 'set -euo pipefail', *lines,
                 '# REPLY carries the result; functions return shell status 0 on success.', 'REPLY=0']
    elif lang == 'go':
        lines += ['', 'package main', '', 'import "fmt"']
    elif lang == 'powershell':
        lines += ['Set-StrictMode -Version Latest', "$ErrorActionPreference = 'Stop'"]
    lines.append('')
    argnames = [v(p) for p in params]
    if lang == 'nim':
        lines.append('proc ' + name + '(' + ', '.join(p + '_arg: int64' for p in argnames) + '): int64 =')
        lines.extend('    var ' + p + ' = ' + p + '_arg' for p in argnames)
        lines.extend('    var ' + v(p) + ': int64 = 0' for p in locals_)
    elif lang == 'rust':
        lines += ['#[allow(unused_mut, unused_assignments)]', 'fn ' + name + '(' + ', '.join('mut '+p+': i64' for p in argnames) + ') -> i64 {']
        lines.extend('    let mut ' + v(p) + ': i64 = 0;' for p in locals_)
    elif lang == 'go':
        lines.append('func ' + name + '(' + ', '.join(p+' int64' for p in argnames) + ') int64 {')
        lines.extend('    var ' + v(p) + ' int64' for p in locals_)
    elif lang == 'php':
        lines.append('function ' + name + '(' + ', '.join('int $'+p for p in argnames) + '): int {')
    elif lang == 'powershell':
        lines.append('function Invoke-Example {')
        lines.append('    param(' + ', '.join('[long]$'+p for p in argnames) + ')')
    elif lang == 'ruby':
        lines.append('def ' + name + '(' + ', '.join(argnames) + ')')
    elif lang == 'bash':
        lines.append(name + '() {')
        lines.extend('    local ' + p + '="${' + str(i+1) + ':?missing argument}"' for i,p in enumerate(argnames))
        if locals_:
            lines.append('    local ' + ' '.join(v(p)+'=0' for p in locals_))
    lines.extend(body(fn.body,lang))
    if lang in ('rust','go','php','powershell','bash'):
        lines.append('}')
    elif lang == 'ruby':
        lines.append('end')
    lines.append('')
    if lang == 'nim':
        lines.append('when isMainModule:')
    elif lang == 'rust':
        lines.append('fn main() {')
    elif lang == 'go':
        lines.append('func main() {')
    indent = '    ' if lang in ('nim','rust','go') else ''
    for i,(args,expected) in enumerate(cases,1):
        joined = ', '.join(map(str,args))
        call = name + '(' + joined + ')'
        label = f'{name} fixture {i}: {args} -> {expected}'
        if lang == 'nim':
            lines.append(indent + f'doAssert {call} == {expected}, "{label}"')
        elif lang == 'rust':
            lines.append(indent + f'assert_eq!({call}, {expected}, "{label}");')
        elif lang == 'go':
            lines.extend([indent+f'if got := {call}; got != {expected} {{', indent+f'    panic(fmt.Sprintf("{label}; got %d", got))',indent+'}'])
        elif lang == 'php':
            lines.extend([f'if ({call} !== {expected}) {{', f'    throw new RuntimeException("{label}");','}'])
        elif lang == 'powershell':
            call = '(Invoke-Example ' + ' '.join(map(str,args)) + ')'
            lines.append(f'if ({call} -ne {expected}) {{ throw "{label}" }}')
        elif lang == 'ruby':
            lines.append(f'raise "{label}" unless {call} == {expected}')
        elif lang == 'bash':
            lines.extend([name + ' ' + ' '.join(map(str,args)), f'if (( REPLY != {expected} )); then',f'    printf \'%s; got %s\\n\' \'{label}\' "$REPLY" >&2', '    exit 1', 'fi'])
    message = f'{name}: {len(cases)} fixtures passed'
    lines.append(indent + {'nim':f'echo "{message}"','rust':f'println!("{message}");','go':f'fmt.Println("{message}")', 'php':f'echo "{message}\\n";', 'powershell':f'Write-Output "{message}"','ruby':f'puts "{message}"','bash':f'printf \'%s\\n\' \'{message}\''}[lang])
    if lang in ('rust','go'):
        lines.append('}')
    return '\n'.join(lines) + '\n'

class Batch:
    def __init__(self):
        self.lines = []
        self.counter = 0
    def label(self):
        self.counter += 1
        return 'branch_' + str(self.counter)
    def expression(self,node):
        # SET /A expands environment identifiers directly, with %% as modulo.
        return expr(node,'cmd').replace('%','%%')
    def branch_false(self, condition, target):
        left = self.expression(condition.left)
        right = self.expression(condition.comparators[0])
        op = {ast.Eq:'neq',ast.NotEq:'equ',ast.Lt:'geq',ast.LtE:'gtr',ast.Gt:'leq',ast.GtE:'lss'}[type(condition.ops[0])]
        self.lines += [f'set /a "condition_left={left}" >nul',f'set /a "condition_right={right}" >nul',f'if !condition_left! {op} !condition_right! goto :{target}']
    def emit(self,nodes):
        for node in nodes:
            if isinstance(node,ast.Assign):
                self.lines.append('set /a "' + v(node.targets[0].id) + '=' + self.expression(node.value) + '" >nul')
            elif isinstance(node,ast.Return):
                self.lines += ['set /a "computed=' + self.expression(node.value) + '" >nul','endlocal & set "REPLY=%computed%" & exit /b 0']
            elif isinstance(node,ast.If):
                other, end = self.label(), self.label()
                self.branch_false(node.test,other)
                self.emit(node.body)
                self.lines += ['goto :'+end, ':'+other]
                self.emit(node.orelse)
                self.lines += [':'+end]
            elif isinstance(node,ast.While):
                start, end = self.label(), self.label()
                self.lines += [':'+start]
                self.branch_false(node.test,end)
                self.emit(node.body)
                self.lines += ['goto :'+start, ':'+end]
            else:
                raise TypeError(ast.dump(node))

def render_batch(fn,cases,contract):
    params, locals_ = names(fn)
    lines = ['@echo off', 'setlocal EnableExtensions EnableDelayedExpansion',
             'rem '+fn.name.replace('_',' ').capitalize()+'.',
             'rem '+LABEL['cmd'], 'rem Contract: '+contract,
             'rem CALL a subroutine; use REPLY for a result instead of an 8-bit exit code.', '']
    for i,(args,expected) in enumerate(cases,1):
        lines += ['call :compute '+' '.join(map(str,args)),f'if not "!REPLY!"=="{expected}" (',f'  echo FAIL {fn.name} fixture {i}: expected {expected}, got !REPLY! 1>&2','  exit /b 1',')']
    lines += [f'echo {fn.name}: {len(cases)} fixtures passed','exit /b 0','',':compute','setlocal EnableDelayedExpansion']
    lines += ['set "'+v(p)+'=%~'+str(i+1)+'"' for i,p in enumerate(params)]
    compiler = Batch()
    compiler.emit(fn.body)
    lines.extend(compiler.lines)
    return '\n'.join(lines)+'\n'

class Assembly:
    def __init__(self,fn):
        params, locals_ = names(fn)
        self.slots = {name:8*(i+1) for i,name in enumerate(params+locals_)}
        self.lines = []
        self.counter = 0
    def label(self):
        self.counter += 1
        return '.branch_'+str(self.counter)
    def expression(self,node):
        if isinstance(node,ast.Constant):
            self.lines.append(f'    mov rax, {node.value}')
        elif isinstance(node,ast.Name):
            self.lines.append(f'    mov rax, [rbp-{self.slots[node.id]}]')
        elif isinstance(node,ast.UnaryOp):
            self.expression(node.operand)
            self.lines.append('    neg rax')
        elif isinstance(node,ast.BinOp):
            self.expression(node.left)
            self.lines.append('    push rax')
            self.expression(node.right)
            self.lines += ['    mov rcx, rax','    pop rax']
            if isinstance(node.op,ast.Add):
                self.lines.append('    add rax, rcx')
            elif isinstance(node.op,ast.Sub):
                self.lines.append('    sub rax, rcx')
            elif isinstance(node.op,ast.Mult):
                self.lines.append('    imul rax, rcx')
            else:
                self.lines += ['    cqo','    idiv rcx']
                if isinstance(node.op,ast.Mod):
                    self.lines.append('    mov rax, rdx')
        else:
            raise TypeError(ast.dump(node))
    def branch_false(self,node,target):
        self.expression(node.left)
        self.lines.append('    push rax')
        self.expression(node.comparators[0])
        self.lines += ['    mov rcx, rax','    pop rax','    cmp rax, rcx']
        op = {ast.Eq:'jne',ast.NotEq:'je',ast.Lt:'jge',ast.LtE:'jg',ast.Gt:'jle',ast.GtE:'jl'}[type(node.ops[0])]
        self.lines.append(f'    {op} {target}')
    def emit(self,nodes):
        for node in nodes:
            if isinstance(node,ast.Assign):
                self.expression(node.value)
                self.lines.append(f'    mov [rbp-{self.slots[node.targets[0].id]}], rax')
            elif isinstance(node,ast.Return):
                self.expression(node.value)
                self.lines += ['    leave','    ret']
            elif isinstance(node,ast.If):
                other,end = self.label(),self.label()
                self.branch_false(node.test,other)
                self.emit(node.body)
                self.lines += ['    jmp '+end,other+':']
                self.emit(node.orelse)
                self.lines.append(end+':')
            elif isinstance(node,ast.While):
                start,end = self.label(),self.label()
                self.lines.append(start+':')
                self.branch_false(node.test,end)
                self.emit(node.body)
                self.lines += ['    jmp '+start,end+':']
            else:
                raise TypeError(ast.dump(node))

def render_asm(fn,cases,contract):
    compiler = Assembly(fn)
    registers = ['rdi','rsi','rdx']
    params,_ = names(fn)
    lines = ['; '+fn.name.replace('_',' ').capitalize()+'.','; '+LABEL['assembly'],
             '; Contract: '+contract,
             '; nasm -f elf64 FILE.asm -o demo.o && ld demo.o -o demo && ./demo',
             '; RAX is the signed result. All scratch registers are caller-saved.',
             '; Each fixture exits with its one-based index on failure; 0 means success.',
             'bits 64','default rel','global _start','section .text','_start:']
    for i,(args,expected) in enumerate(cases,1):
        lines += [f'    mov {registers[j]}, {arg}' for j,arg in enumerate(args)]
        lines += ['    call compute',f'    cmp rax, {expected}',f'    jne fail_{i}']
    lines += ['    xor edi, edi','    mov eax, 60','    syscall']
    for i in range(1,len(cases)+1):
        lines += [f'fail_{i}:',f'    mov edi, {i}','    mov eax, 60','    syscall']
    lines += ['','compute:','    push rbp','    mov rbp, rsp',f'    sub rsp, {((len(compiler.slots)*8+15)//16)*16}']
    lines += [f'    mov [rbp-{compiler.slots[p]}], {registers[i]}' for i,p in enumerate(params)]
    compiler.emit(fn.body)
    lines.extend(compiler.lines)
    lines += ['', 'section .note.GNU-stack noalloc noexec nowrite progbits']
    return '\n'.join(lines)+'\n'

def build():
    ROOT.mkdir(parents=True,exist_ok=True)
    functions = [n for n in ast.parse(inspect.getsource(specs)).body if isinstance(n,ast.FunctionDef)]
    # Interleave domains to keep every language's subset varied even when its
    # syntax reaches the budget sooner. No repeated files are used as padding.
    functions = [functions[i] for offset in range(5) for i in range(offset,len(functions),5)]
    manifest = []
    for lang,ext in EXT.items():
        total = 0
        destination = ROOT / lang
        destination.mkdir(exist_ok=True)
        for index,fn in enumerate(functions,1):
            cases = specs.CASES[fn.name]
            for args,expected in cases:
                got = getattr(specs,fn.name)(*args)
                assert got == expected, (fn.name,args,expected,got)
            contract = specs.CONTRACTS.get(fn.name,'Nonnegative integer inputs; keep all intermediate values within signed 32-bit range. See the fixtures for supported examples.')
            if lang == 'cmd':
                source = render_batch(fn,cases,contract)
            elif lang == 'assembly':
                source = render_asm(fn,cases,contract)
            else:
                source = render_high(fn,lang,cases,contract)
            if lang == 'go':
                formatter = shutil.which('gofmt')
                if not formatter:
                    raise RuntimeError('Install Go and put gofmt on PATH before regenerating.')
                source = subprocess.run([formatter], input=source, text=True,
                                        capture_output=True, check=True).stdout
            prefix = 'sample_' if lang == 'nim' else ''
            path = destination / f'{prefix}{index:02}_{fn.name}.{ext}'
            path.write_text(source,encoding='utf-8',newline='\r\n' if lang == 'cmd' else '\n')
            count = tokens(source)
            raw = path.read_bytes()
            manifest.append({'path':path.relative_to(ROOT).as_posix(),'language':lang,'tokens':count,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'fixtures':len(cases)})
            total += count
            if total >= (10000 if lang == 'go' else 10200):
                break
        print(lang, total, 'tokens', index, 'files')
    (ROOT / 'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    build()
