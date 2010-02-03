" Vim syntax file
" Language:	Quickfix window
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2001 Jan 15

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" A bunch of useful C keywords
syn match	qfFileName	"^[^|]*" nextgroup=qfSeparator
syn match	qfSeparator	"|" nextgroup=qfLineNr contained
syn match	qfLineNr	"[^|]*" contained contains=qfError
syn match	qfError		"error" contained

syn match	qfShcmd		"^|*\s*\[.*@.*\].*$" contains=qfShTime,qfShDir,qfShFile
syn match	qfShTime	"\d\d.\d\d.\d\d" contained
syn match	qfShFile	":.*\]"hs=s+1,he=e-1 contained
syn match	qfShDir		"@[^:]*"hs=s+1 contained
syn match	qfShInnercmd	"^|*\s*>>.*$"
syn match	qfShInterrupt	"^|*\s*Vim:Interrupt\s*$"
syn match	qfShFail	"^|*\s*ExecuteCommand failed:.*$"

" The default highlighting.
hi def link qfFileName		Directory
hi def link qfLineNr		LineNr
hi def link qfError		Error

hi def	    qfShcmd		ctermfg=green guifg=green
hi def	    qfShTime		ctermfg=red guifg=red
hi def	    qfShFile		ctermfg=yellow guifg=yellow
hi def	    qfShDir		ctermfg=darkcyan guifg=darkcyan
hi def	    qfShInnercmd	ctermfg=gray guifg=gray
hi def	    qfShInterrupt	ctermfg=red guifg=red
hi def	    qfShFail		ctermfg=red guifg=red

let b:current_syntax = "qf"

" vim: ts=8
