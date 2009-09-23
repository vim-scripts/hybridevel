" Vim development plugin for flash project
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:flash_development_loaded") && b:flash_development_loaded==1
	finish
endif
let b:flash_development_loaded=1

function! g:FlashInitProject()
    call g:RegisterFunction("g:ExpandSource","g:FlashExpandSource")
    call g:RegisterFunction("g:TranslateToExecutor","g:FlashTranslateToExecutor")
	
	let t:flash_source_definition="/r/d/m/=/,/"
	let t:flash_destination_definition="/r/d/s/"
	let t:flash_library_definition="/o/i:swc/m/+=/M/"
	let t:flash_argumentfile_definition="/o/f/s/"
	let t:flash_airdescription_definition="/o/f/s/"

	let t:flash_source_candidacy="src:flash_src:actionscript_src"
	let t:flash_destination_candidacy="bin:flash_bin:WebRoot/flashes"
	let t:flash_library_candidacy="lib:flash_lib:actionscript_lib"
	let t:flash_argumentfile_candidacy="flash-config.xml:flex-config.xml:air-config.xml"
	let t:flash_airdescription_candidacy="air-app.xml"
	
	let t:flash_compile_command="mxmlc +configname=air -output[destination] -compiler.library-path[library] -compiler.source-path[source] -load-config[argumentfile] COMPILEOPTIONS TARGET"
	let t:flash_interpret_command="flashplayer PROGRAM"
	let t:flash_debug_command="adl [airdescription] {g:Project.root} -- ARGUMENTS"

	let t:flash_build="compile:debug"
	let t:flash_suffixes="as:mxml"
endfunction

function! g:FlashTranslateToExecutor(sourcefile)
	return g:GetOptionValue('destination','').'/'.g:Project.name.'.swf'
endfunction

function! g:FlashExpandSource(sourcefile)
	let ext=fnamemodify(a:sourcefile,':e')
	if ext=='mxml'
		return '/'.fnamemodify(a:sourcefile,':t')
	endif
	return "/".substitute(s:GetFullClassName(a:sourcefile),'\.',"/","g").".".ext
endfunction

function! g:Get_flash_destination_value(cmd,option)
	return g:FlashTranslateToExecutor(g:Project.flash.main)
endfunction

function! s:GetFullClassName(sourcefile)
	let package=s:GetPackage(a:sourcefile)
	let class=fnamemodify(a:sourcefile,":t:r")
	if package=='' || fnamemodify(a:sourcefile,':e')=='mxml'
		return class
	endif
	return package.'.'.class
endfunction
	
function! s:GetPackage(class)
	let package=""
	let lines=readfile(a:class)
	let index=match(lines,'^\(\s\|[^:print:]\)*package\(\s.*\)\?')
	if index!=-1
		try
			let package=split(split(lines[index])[1],'{')[0]
		catch /.*/
			call g:EchoErrorMsg("The package definition may incorrect!")
		endtry
	endif
	return package
endfunction

call g:RegisterFunction("g:InitProject","g:FlashInitProject")
