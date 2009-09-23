" Vim development plugin for scheme project
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Feb 09
"

if exists("b:java_development_loaded") && b:java_development_loaded==1
	finish
endif
let b:java_development_loaded=1

function! g:JavaInitProject()
    call g:RegisterFunction("g:ExpandSource","g:JavaExpandSource")
    call g:RegisterFunction("g:TranslateToExecutor","g:JavaTranslateToExecutor")
	
	let t:java_source_definition="/r/d/m/"
	let t:java_destination_definition="/r/d/s/"
	let t:java_library_definition="/o/i:jar:zip/m/ /:/CLASSPATH/"
	let t:java_resource_definition="/o/v/m/"
	let t:java_binary_definition="/o/d/s/"
	let t:java_argumentfile_definition="/o/f/m//M/"
	let t:java_manifest_definition="/o/f/s/"

	let t:java_source_candidacy="src:java_src"
	let t:java_destination_candidacy="classes:java_class:WebRoot/WEB-INF/classes"
	let t:java_library_candidacy="lib:java_lib:WebRoot/WEB-INF/lib"
	let t:java_resource_candidacy="res"
	let t:java_binary_candidacy="bin"
	let t:java_argumentfile_candidacy="classpath.javac:option.javac:source.javac"
	let t:java_manifest_candidacy="MANIFEST.MF"
	
	let t:java_compile_command="javac -d[destination] -classpath[library] -sourcepath[source] COMPILEOPTIONS TARGET @[argumentfile]"
	let t:java_interpret_command="java -classpath[library] EXECUTEOPTIONS PROGRAM ARGUMENTS"
	let t:java_jar_command="jar -cvfme [binary] [manifest] PROGRAM -C PROJECTROOT [resource] -C[destination] ."

	let t:java_build='compile:interpret'
	let t:java_suffixes='java'
	
	let main='^\s*\(\(public\|static\)\s\+\)\{2}void\s\+main(String'
	let para1=main.'\(\(\s*\(\.\{3}\|[]\)\s*\)\w\+\s*\))'
	let para2=main.'\(\s\+\w\+\s*[]\s*\))'
	let t:java_mains=[para1,para2]
	let t:java_checkrange=0
endfunction

function! g:JavaTranslateToExecutor(sourcefile)
	return s:GetFullClassName(a:sourcefile)
endfunction

function! g:JavaExpandSource(sourcefile)
	return "/".substitute(s:GetFullClassName(a:sourcefile),'\.',"/","g").'.'.fnamemodify(a:sourcefile,":e")
endfunction

function! g:Get_java_library_value(cmd,option)
	let dest=g:GetOptionValue('destination','')
	let libs=g:GetOptionValue('library','CLASSPATH')
	return libs!=""?substitute(libs,'^\(\.\/:\)\=',dest.':','g'):dest
endfunction

function! g:Get_java_binary_value(cmd,option)
	return g:GetOptionValue("binary",'').'/'.g:Project.name.'.jar'
endfunction

" Other Functions
function! s:GetFullClassName(sourcefile)
	let package=s:GetPackage(a:sourcefile)
	let class=fnamemodify(a:sourcefile,":t:r")
	if strlen(package)>0
		return package.'.'.class
	else
		return class
	endif
endfunction
	
function! s:GetPackage(class)
	let package=""
	let lines=readfile(a:class)
	let index=match(lines,'^\(\s\|[^:print:]\)*package\s.*')
	if index!=-1
		try
			let package=split(split(lines[index])[1],';')[0]
		catch /.*/
			call g:EchoErrorMsg("The package definition may incorrect!")
		endtry
	endif
	return package
endfunction

call g:RegisterFunction("g:InitProject","g:JavaInitProject")
