" Vim development plugin for c project
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:cpp_development_loaded") && b:cpp_development_loaded==1
	finish
endif
let b:cpp_development_loaded=1

function! g:CppInitProject()
	let t:cpp_destination_definition='/r/d/s'
	let t:cpp_source_definition='/r/i:cpp/m'
	let t:cpp_library_definition='/o/d/m//M/LD_LIBRARY_PATH'
	let t:cpp_include_definition='/o/d/m//M/'
	let t:cpp_argumentfile_definition='/o/f/m//M/'

	let t:cpp_source_candidacy="src:c_src:cpp_src"
	let t:cpp_destination_candidacy="bin"
	let t:cpp_library_candidacy="lib:c_lib:cpp_lib"
	let t:cpp_include_candidacy="include:c_include:public_include"
	let t:cpp_argumentfile_candidacy="lib.gccc:include.gccc:source.gccc"
	
	let t:cpp_compile_command="g++ -Wall -g3 -O3 -pipe -fexceptions -fstack-protector -fasynchronous-unwind-tables -o[destination] -I[include] -L[library] COMPILEOPTIONS TARGET @[argumentfile]"
	let t:cpp_interpret_command="PROGRAM ARGUMENTS"
	let t:cpp_qt_command="qmake -makefile"

	let t:cpp_build='compile:interpret'
	let t:cpp_suffixes='cpp'
		
	let t:cpp_mains=['^\s*int\s\+main(.\+)']
endfunction

function! g:Get_cpp_TARGET_value(cmd,option)
	if filereadable(g:Project.root."/.vimproject")
		return substitute(g:GetOptionValue('source',''),':',' ','g')
	else
		return g:Project.current.main==""?bufname("%"):g:Project.current.main
	endif
endfunction

function! g:Get_cpp_destination_value(cmd,option)
	return g:TranslateToExecutor(g:Project.current.main)
endfunction

call g:RegisterFunction("g:InitProject","g:CppInitProject")
