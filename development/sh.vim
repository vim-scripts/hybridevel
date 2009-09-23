" Vim development plugin for shell script
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:sh_development_loaded") && b:sh_development_loaded==1
	finish
endif
let b:sh_development_loaded=1

function! g:ShInitProject()
	let t:sh_chmod_command="chmod a+x TARGET"
	let t:sh_interpret_command="TARGET ARGUMENTS"

	let t:sh_build='chmod:interpret'
	let t:sh_suffixes='...'
	
	let t:sh_mains=['^\s*#!']
	let t:sh_checkrange=20

	let t:sh_keepmain=0
	let t:sh_keepconfigfile=0
endfunction

call g:RegisterFunction("g:InitProject","g:ShInitProject")
