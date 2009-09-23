" Vim development plugin for c project
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:c_development_loaded") && b:c_development_loaded==1
	finish
endif
let b:c_development_loaded=1

function! g:CInitProject()
	let t:c_destination_definition='/r/d/s'
	let t:c_source_definition='/r/i:c/m'
	let t:c_library_definition='/o/d/m//M/LD_LIBRARY_PATH'
	let t:c_include_definition='/o/d/m//M/'
	let t:c_argumentfile_definition='/o/f/m//M/'

	let t:c_source_candidacy="src:c_src"
	let t:c_destination_candidacy="bin"
	let t:c_library_candidacy="lib:c_lib"
	let t:c_include_candidacy="include:c_include:public_include"
	let t:c_argumentfile_candidacy="lib.gccc:include.gccc:source.gccc"
	
	let t:c_compile_command="gcc -Wall -g3 -O3 -pipe -fexceptions -fstack-protector -fasynchronous-unwind-tables -o[destination] -I[include] -L[library] COMPILEOPTIONS TARGET @[argumentfile]"
	let t:c_interpret_command="PROGRAM ARGUMENTS"

	let t:c_build='compile:interpret'
	let t:c_suffixes='c'
		
	let t:c_mains=['^\s*int\s\+main(.\+)']
endfunction

function! g:Get_c_TARGET_value(cmd,option)
	if filereadable(g:Project.root."/.vimproject")
		return substitute(g:GetOptionValue('source',''),':',' ','g')
	else
		return g:Project.current.main==""?bufname("%"):g:Project.current.main
	endif
endfunction

function! g:Get_c_destination_value(cmd,option)
	return g:TranslateToExecutor(g:Project.current.main)
endfunction

call g:RegisterFunction("g:InitProject","g:CInitProject")
