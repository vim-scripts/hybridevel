" Vim development plugin for make project
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:make_development_loaded") && b:make_development_loaded==1
	finish
endif
let b:make_development_loaded=1

function! g:MakeInitProject()
	let t:make_compile_command="gmake -f TARGET compile"
	let t:make_interpret_command="gmake -f TARGET run"
	let t:make_default_command="gmake -f TARGET"
	
	let t:make_build='default'
	let t:make_suffixes='mk:mak::dsp'
	let t:make_default="Makefile"
endfunction
	
call g:RegisterFunction("g:InitProject","g:MakeInitProject")
