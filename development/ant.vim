" Vim development plugin for make project
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:ant_development_loaded") && b:ant_development_loaded==1
	finish
endif
let b:ant_development_loaded=1

function! g:AntInitProject()
	let t:ant_compile_command="ant -buildfile TARGET compile"
	let t:ant_interpret_command="ant -buildfile TARGET run"
	let t:ant_default_command="ant -buildfile TARGET"
	
	let t:ant_build='default'
	let t:ant_suffixes='xml'
	let t:ant_default='build.xml'
endfunction
	
call g:RegisterFunction("g:InitProject","g:AntInitProject")
