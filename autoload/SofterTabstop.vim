" SofterTabstop.vim - SofterTabstop plugin for vim
" ----------------------------------------------------------------------------
" Version:      0.1
" License:      GPLv2+
" Copyright:    Yclept Nemo <pscjtwjdjtAhnbjm/dpn>
" ----------------------------------------------------------------------------


python << endpython
import vim
import enum


class Direction(enum.Enum):
    Up      = 0
    Down    = 1


def get_var(name, default):
    return vim.eval("exists('{}')?({}):({})".format(name, name, default))

def lines(index, limit, direction):
    lines = len(vim.current.buffer)
    while 0 <= index < lines and limit > 0:
        yield vim.current.buffer[index]
        if direction is Direction.Up:
            index -= 1
        else:
            index += 1
        limit -= 1

def indent_of(line, tabsize):
    line = line.expandtabs(tabsize)
    return len(line) - len(line.lstrip())

def previous_indent_first(index, tabsize, cindent, limit, direction):
    for line in lines(index, limit, direction):
        if not line.isalpha():
            lindent = indent_of(line, tabsize)
            if lindent < cindent:
                return lindent
    return 0

def next_indent_nearest(index, tabsize, cindent, limit, direction):
    indents = [0]
    for line in lines(index, limit, direction):
        if not line.isalpha():
            lindent = indent_of(line, tabsize)
            if cindent < lindent:
                indents.append(lindent)
            if cindent+1 >= lindent:
                break
    return min(indents, key=lambda i: abs(i-cindent))

def backspace_character(count):
    return " " + "\b" * (count + 1)

def backspace_characters(limit_up, limit_down):
    align = int(get_var("b:soft_mode_align", 1))
    if not align:
        return backspace_character(1)
    softtab = int(vim.eval("&softtabstop"))
    if softtab == 0:
        return backspace_character(1)
    row,col = vim.current.window.cursor
    cindent = indent_of(vim.current.line, softtab)
    if col > cindent or col == 0:
        return backspace_character(1)
    pindent = min\
        ( previous_indent_first(row-2, softtab, cindent, limit_up,   Direction.Up)
        , previous_indent_first(row,   softtab, cindent, limit_down, Direction.Down)
        , key=lambda i: abs(i-cindent)
        )
    stsdent = max(0, divmod(col+softtab-1, softtab)[0] - 1) * softtab
    if stsdent < pindent < col:
        return backspace_character(col - pindent)
    else:
        return backspace_character(col - stsdent)

def tab_characters(limit_up, limit_down):
    softtab = int(vim.eval("&softtabstop"))
    if softtab == 0:
        return "\t"
    row,col = vim.current.window.cursor
    cindent = indent_of(vim.current.line, softtab)
    nindent = min\
        ( next_indent_nearest(row-2, softtab, cindent, limit_up,   Direction.Up)
        , next_indent_nearest(row,   softtab, cindent, limit_down, Direction.Down)
        , key=lambda i: abs(i-cindent)
        )
    stsdent = (divmod(col, softtab)[0] + 1) * softtab
    if col < nindent < stsdent:
        return " " * (nindent - col)
    else:
        return "\t"
endpython


function! SofterTabstop#SoftBackspace(...)
python << endpython
limit_up    = int(get_var("a:1", 25))
limit_down  = int(get_var("a:2", 5))
vim.command("return '{}'".format(backspace_characters(limit_up, limit_down)))
endpython
endfunction

function! SofterTabstop#SoftTab(...)
python << endpython
limit_up    = int(get_var("a:1", 25))
limit_down  = int(get_var("a:1", 5))
vim.command("let b:soft_mode_align=1")
vim.command("return '{}'".format(tab_characters(limit_up, limit_down)))
endpython
endfunction

function! SofterTabstop#SoftSpace()
python << endpython
softtab = int(vim.eval("&softtabstop"))
row,col = vim.current.window.cursor
cindent = indent_of(vim.current.line, softtab)
if col <= cindent:
    vim.command("let b:soft_mode_align=0")
vim.command("return ' '")
endpython
endfunction

function! SofterTabstop#SoftEnter()
    let b:soft_mode_align=1
    return "\n"
endfunction
