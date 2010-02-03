"" Vim global plugin for hybird projects 
" Version: 8.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2010 Feb 01
"*******************************************************************************

if exists("b:load_development") && b:load_development==1
	finish
endif
let b:load_development=1

if !exists("g:ProjectAuthor")
	let g:ProjectAuthor="<a href='mainto:juzhenliang@gmail.com'>WarGrey</a>"
endif

if !exists("g:ProjectManager")
	let g:ProjectManager="make:ant:maven"
endif

" Ex command which take 0 or more ( up to 20 ) parameters
command! -complete=file -nargs=* Compile call <SID>CLCompileProject(<f-args>)
command! -complete=file -nargs=* Execute call <SID>CLExecuteProject(<f-args>)
command! -complete=file -nargs=* Build call <SID>CLBuildProject(<f-args>)
command! -complete=file -nargs=* Shell call g:ExecuteCommand(<f-args>)

" Map keys to function calls
map <unique> <F9> :call <SID>InvokeToggleMain()<CR>
map <unique> <M-F9> :messages<CR>
map <unique> <F5> :call <SID>CompileProject()<CR>
map <unique> <M-F5> :Shell :Compile 
map <unique> <F6> :call <SID>ExecuteProject()<CR>
map <unique> <M-F6> :Shell :Execute 
map <unique> <F8> :call <SID>BuildProject()<CR>
map <unique> <M-F8> :Shell :Build 

imap <unique> <F9> <ESC><F9>a
imap <unique> <M-F9> <ESC><M-F9>a
imap <unique> <F5> <ESC><F5>
imap <unique> <M-F5> <ESC><M-F5>
imap <unique> <F6> <ESC><F6>
imap <unique> <M-F6> <ESC><M-F6>
imap <unique> <F8> <ESC><F8>
imap <unique> <M-F8> <ESC><M-F8>

let s:CurrentCommandResult=''
let s:LastModifiedTime=0
let s:FromCommandLine=0
let s:Functions=[]

function! s:DefaultInitProject()
    call g:RegisterFunction("g:CheckMain","g:DefaultCheckMain")
	call g:RegisterFunction('g:DeposeProject','g:DefaultDeposeProject')
    call g:RegisterFunction("g:ExpandSource","g:DefaultExpandSource")
    call g:RegisterFunction("g:TranslateToExecutor","g:DefaultTranslateToExecutor")
	
	if !exists("g:Project")
		let g:Project={'root':'','name':'','version':'1.0','author':g:ProjectAuthor,'current':{}}
	endif
endfunction

function! s:InvokeToggleMain()
	try
		call s:ToggleMain()
	catch /.*/
		call g:EchoErrorMsg("Toggle Main Failed: ".v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

function! s:InitEnvironment()
	let currentType=s:GetCurrentType()
	let cprt=g:Project.root
	let tail=substitute(g:ExpandSource(g:Project.current.main),'^/*','/','g')
	let src=fnamemodify(g:Project.current.main,":p")
	if src=~tail.'$'
		let src=substitute(src,tail.'$','','g')
	else
		let src=fnamemodify(src,":p:h")
		call g:EchoErrorMsg("This source file may locate in an incorrect directory!")
	endif

	let csrc=src
	let g:Project.root=src
	let isProjectEnvironment=0
	while src!=fnamemodify(src,":h")
		if filereadable(src.'/.vimproject')
			let g:Project.root=src
			let isProjectEnvironment=1
			call s:ReadProjectConfigFile()
			break
		endif
	
		let pass=1
		for var in g:GetDefinedVariables('r..')
			let value=get(t:,currentType.'_'.var.'_candidacy',"")
			if empty(filter(split(value,":"),'g:FileExists(src."/".v:val)'))
				let pass=0
				break
			endif
		endfor
		if pass==1
			let g:Project.root=src
			let isProjectEnvironment=1
			break
		endif

		let src=fnamemodify(src,":h")
	endwhile
	if g:GetDefinitionSign('source',1)=~'^r' && empty(filter(filter(split(get(t:,currentType.'_source_candidacy',''),':'),'isdirectory(g:Project.root."/".v:val)')+split(get(g:Project.current.variable,'source',''),':'),'g:Project.root."/".v:val==csrc'))
		let isProjectEnvironment=0
		let g:Project.root=csrc
	endif

	let keywordsign=&iskeyword
	set iskeyword+=_
	for [var,value] in items(filter(deepcopy(t:),'v:key=~"^".currentType."_\\k*_candidacy$"'))
		let varparts=split(var,'_')
		if len(varparts)<3
			call g:EchoWarningMsg("Invalid variable name: ".varparts)
			continue
		endif
		
		let varname=join(varparts[1:-2],'_')
		if isProjectEnvironment==0 && g:GetDefinitionSign(varname,2)=~'^[di]'
			let g:Project['current']['variable'][varname]=csrc
			continue
		endif

		let items=g:FilterOptionValue(get(g:Project.current.variable,varname,'').':'.value)
		if items==''
			continue
		endif
		if g:GetDefinitionSign(varname,3)=~'^s'
			let items=split(items,':')[0]
		endif
		let g:Project['current']['variable'][varname]=items
	endfor
	let &iskeyword=keywordsign
	
	if g:Project.name==''
		let g:Project.name=fnamemodify(g:Project.root,':t')
	endif
	if g:Project['version']==''
		let g:Project['version']=1.0
	endif
	if g:Project.author==''
		let g:Project.author="<a href='juzhenliang@gmail.com'>WarGrey</a>"
	endif

	if isProjectEnvironment==1 && get(t:,currentType.'_keepconfigfile',1)>0
		call s:WriteProjectConfigFile()
	endif

	call g:EchoMoreMsg("[".currentType."]The project root is ".g:Project.root)
	if cprt!=g:Project.root && cprt!=''
		call g:EchoWarningMsg("This project is not the original one: ".cprt)
	endif
endfunction

function! s:ReadProjectConfigFile()
	let keywordsign=&iskeyword
	set iskeyword+=_
	let configFile=g:Project.root.'/.vimproject'
	let lmt=getftime(configFile)
	if !filereadable(configFile) || s:LastModifiedTime==lmt
		return
	endif

	let s:LastModifiedTime=lmt
	let configurations=readfile(configFile)
	let functions=[]
	let target=''
	let index=0
	while index<len(configurations)
		let index=index+1
		let configuration=g:Trim(configurations[index-1])
		if configuration=="" || configuration=~'^["]'
			continue
		endif

		if configuration=~'^\[\k*\]$'
			let target=configuration[1:-2]
			if !has_key(g:Project,target)
				call s:AllocateSpace(target)
			endif
		elseif configuration=~'^\<function\>'
			let configuration=substitute(configuration,'^\<function\>!\? \(\K:\)\?','function! g:','g')
			while configuration!~'^\<endfunction\>$'
				call add(functions,configuration)
				let configuration=configurations[index]
				let index=index+1
			endwhile
			call extend(functions,['endfunction',''])
		else
			if match(configuration,'=')==-1
				call g:EchoWarningMsg("The Variable Name may incorrect: line ".index-1)
				continue
			endif
			let config=split(configuration,'=')
			if len(config)<2
				call g:EchoWarningMsg("Empty variable, Ignored: ".config[0])
				continue
			endif
			let value=substitute(join(config[1:-1],'='),'\(^"*\)\|\("*$\)','','g')
			let value=substitute(value,"\\(^'*\\)\\|\\('*$\\)",'','g')
			if target==''
				let g:Project[config[0]]=value
				continue
			endif
			if config[0]=='build_commands'
				if value!=''
					let g:Project[target]['build']=value
				endif
			elseif config[0]=~'_definition$' || config[0]=~'_command$'
				let configparts=split(config[0],'_')
				let g:Project[target][configparts[-1]][join(configparts[0:-2],'_')]=value
				if config[0]=~'_definition$'
					call s:CheckDefinition(config[0],value)
				endif
			else
				let g:Project[target]['variable'][config[0]]=value
				for val in split(value,":")
					let fileordir=val!~'^/'?(g:Project.root.'/'.val):val
					if !g:FileExists(fileordir)
						call g:EchoWarningMsg(fileordir.' does not exists!')
					endif
				endfor
			endif
		endif
	endwhile
	if !empty(functions)
		let functionsrc=tempname()
		call writefile(functions,functionsrc)
		execute 'source '.functionsrc
	endif
	let s:Functions=functions
	let &iskeyword=keywordsign
endfunction

function! s:WriteProjectConfigFile()
	let configurations=['" ViM Project Configuration']

	let tps=["name","version","author"]
	let builtin=["root","name","version","author"]
	for key in tps+filter(keys(g:Project),'type(g:Project[v:val])==1 && match(builtin,"^".v:val."$")==-1')
		if g:Project[key]!=''
			call add(configurations,key.'="'.g:Project[key].'"')
		endif
	endfor
	for key in sort(filter(keys(g:Project),'type(g:Project[v:val])==4 && v:val!="current"'))
		if get(t:,key.'_keepconfigfile',1)==0
			continue
		endif
		call extend(configurations,['','['.key.']'])
		if g:Project[key]['build']!=''
			call extend(configurations,['build_commands="'.g:Project[key]['build'].'"',''])
		endif
		for subkey in keys(get(g:Project[key],'command',{}))
			if g:Project[key]['command'][subkey]!=""
				call add(configurations,subkey.'_command="'.g:Project[key]['command'][subkey].'"')
			endif
		endfor
		call add(configurations,'')
		for subkey in keys(get(g:Project[key],'definition',{}))
			if g:Project[key]['definition'][subkey]!=''
				call add(configurations,subkey.'_definition="'.g:Project[key]['definition'][subkey].'"')
			endif
		endfor
		call add(configurations,'')
		for subkey in keys(get(g:Project[key],'variable',{}))
			if g:Project[key]['variable'][subkey]!='' && get(g:Project[key]['definition'],subkey,'')!=''
				call add(configurations,subkey.'="'.g:Project[key]['variable'][subkey].'"')
			endif
		endfor
	endfor
	
	if !empty(s:Functions)
		call extend(configurations,['','" customer functions']+s:Functions)
	endif
	call writefile(configurations,g:Project.root.'/.vimproject')
endfunction

function! s:CompileProject()
	try
		if s:FromCommandLine==0
			call g:Prepare()
		endif
		let s:FromCommandLine=0

		let cmd=g:ParseCommand(get(g:Project.current.command,'compile',""))
		if cmd==''
			throw 'Nothing to do for empty command!'
		endif
		
		try
			call function('g:Do_'.s:GetCurrentType().'_compile')()
			return
		catch /.*E488.*/
		endtry
		call g:ExecuteCommand(cmd)
	catch /.*/
		call g:EchoErrorMsg('Compile failed: '.v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

function! s:CLCompileProject(...)
	try
		call g:Prepare()
		let eoption=join(map(deepcopy(a:000),'g:Trim(v:val)'),' ')
		if eoption!~'^:'
			if match(split(g:Project.current.extraoption.compiler,'<=>'),'^'.eoption.'$')==-1
				let g:Project.current.extraoption.compiler.='<=>'.eoption
			endif
		else
			let g:Project.current.extraoption.compiler=eoption[1:-1]
		endif
		let s:FromCommandLine=1
		call s:CompileProject()
	catch /.*/
		call g:EchoErrorMsg('CLCompile failed: '.v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

function! s:ExecuteProject()
	try
		if s:FromCommandLine==0
			call g:Prepare()
		endif
		let s:FromCommandLine=0

		let cmd=g:ParseCommand(get(g:Project.current.command,'interpret',""))
		if cmd==''
			throw 'Nothing to do for empty command!'
		endif
		
		try
			call function('g:Do_'.s:GetCurrentType().'_interpret')()
			return
		catch /.*E488.*/
		endtry
		call g:ExecuteCommand('>>',cmd)
	catch /.*/
		call g:EchoErrorMsg('Execute failed: '.v:exception.' at '.v:throwpoint.' ')
	finally
		if getfsize('.VIM_STD_IN')==0
			call delete('.VIM_STD_IN')
		endif
	endtry
endfunction

function! s:CLExecuteProject(...)
	try
		call g:Prepare()
		let parms=map(deepcopy(a:000),'g:Trim(v:val)')
		let spt=match(parms,'^--:*$')
		let aoption=(spt==-1)?join(parms,' '):(spt>0)?join(parms[0:spt-1],' '):''
		let eoption=(spt>=0)?join(parms[spt+1:-1]):''
		if eoption!~'^:' || parms[spt]=~':$'
			if match(split(g:Project.current.extraoption.interpreter,'<=>'),'^'.eoption.'$')==-1
				let g:Project.current.extraoption.interpreter.='<=>'.eoption
			endif
		else
			let g:Project.current.extraoption.interpreter=eoption[1:-1]
		endif
		let g:Project.current.extraoption.program=aoption
		let s:FromCommandLine=1
		call s:ExecuteProject()
	catch /.*/
		call g:EchoErrorMsg('CLExecute failed: '.v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

function! s:BuildProject()
	try
		if s:FromCommandLine==0
			call g:Prepare()
		endif
		let s:FromCommandLine=0

		let cmds=split(g:Project.current.extraoption.builder,':')
		if cmds==[]
			let cmds=split(g:Project.current.build,":")
		endif
		if cmds==[]
			throw 'No command needs to execute!'
		endif

		let currentType=s:GetCurrentType()
		for cmdfullname in cmds
			let cmdparts=split(cmdfullname,'\.')
			if len(cmdparts)>1
				let cmdfullname=join(cmdparts[1:-1],'.')
				call s:SetCurrentType(cmdparts[0])
			else
				call s:SetCurrentType(currentType)
			endif
			let cmdname=substitute(cmdfullname,'!$','','g')
			let cmdstr=get(g:Project.current.command,cmdname,'')
			if cmdstr==''
				let error='Command not found: '.cmdfullname.'.'
				if cmdfullname=~'!$'
					call g:EchoWarningMsg(error)
					continue
				else
					throw error
				endif
			endif
		
			let cmd=g:ParseCommand(cmdstr)
			let execmd=cmd[0:match(cmd,' ')]
			try
				call function('g:Do_'.s:GetCurrentType().'_'.cmdname)()
			catch /.*E488.*/
				call g:ExecuteCommand('>>',cmd)
			catch /.*/
				let s:CurrentCommandResult.='ExecuteCommand failed: '.v:exception.' at '.v:throwpoint.' '
			endtry

			if s:CurrentCommandResult!=""
				let lastline=split(s:CurrentCommandResult,'\n')[-1]
				if match(lastline,'^ExecuteCommand failed:')==0
					let error=lastline.'['.execmd.']'
					if cmdfullname=~'!$'
						call g:EchoWarningMsg(error)
					else
						throw error
					endif
				endif
			endif
		endfor
	catch /.*E488.*/
	catch /.*/
		call g:EchoErrorMsg('Build failed: '.v:exception.' at '.v:throwpoint.' ')
	finally
		if getfsize('.VIM_STD_IN')==0
			call delete('.VIM_STD_IN')
		endif
		if exists("currentType")
			call s:SetCurrentType(currentType)
		endif
	endtry
endfunction

function! s:CLBuildProject(...)
	try
		call g:Prepare()
		let oldbuilder=g:Project.current.extraoption.builder
		let g:Project.current.extraoption.builder=join(map(deepcopy(a:000),'g:Trim(v:val)'),':')
		let s:FromCommandLine=1
		call s:BuildProject()
		let g:Project.current.extraoption.builder=oldbuilder
	catch /.*/
		call g:EchoErrorMsg('CLBuild failed: '.v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

" Hook Functions
function! g:DefaultCheckMain(type,sourcefile)
	if !filereadable(a:sourcefile)
		return 0
	endif

	let suffix=fnamemodify(a:sourcefile,":e")
	let suffixes=split(get(t:,a:type.'_suffixes',''),":")
	if match(suffixes,'\.\.\.')==-1 && match(suffixes,'^'.suffix.'$')==-1
		call g:EchoErrorMsg("Unknown Type: ".suffix)
		return 0
	endif

	let mains=get(t:,a:type.'_mains',[])
	if mains==[]
		return 1
	endif

	let checkrange=get(t:,a:type.'_checkrange',0)
	let lines=(checkrange==0)?readfile(a:sourcefile):readfile(a:sourcefile,'',checkrange)
	for main in mains
		if match(lines,main)>-1
			return 1
		endif
	endfor
	call g:EchoWarningMsg(fnamemodify(a:sourcefile,":.").' does not have the main element!')
	return 1
endfunction

function! g:DefaultExpandSource(sourcefile)
	return fnamemodify(a:sourcefile,':t')
endfunction

function! g:DefaultTranslateToExecutor(src)
	let dest=split(g:GetOptionValue('destination',''),":")[0]
	let output=g:Project.name==fnamemodify(g:Project.root,":t")?fnamemodify(a:src,':t:r'):g:Project.name
	return dest.'/'.output
endfunction

function! g:DefaultDeposeProject()
	let currentType=s:GetCurrentType()
	if currentType!=''
		let b:[currentType.'_development_loaded']=0
	endif
endfunction

" Other Functions
function! g:GetDefinedVariables(bits)
	let vars=[]
	for [var,value] in items(g:Project.current.definition)
		let target=join(map(split(value,'/')[0:2],'v:val[0]'),'')
		if match(target,'^'.a:bits.'$')!=-1
			call add(vars,var)
		endif
	endfor
	return vars
endfunction

function! g:GetDefinitionSign(name,bit,...)
	let value=split(get(g:Project.current.definition,a:name,''),'/')
	return a:bit<=len(value)?value[a:bit-1]:a:0==0?'':a:1
endfunction

function! g:Prepare()
	try
		wall
	catch /.*/
		call g:EchoErrorMsg("Save failed: ".v:exception.' at '.v:throwpoint.' ')
	endtry
	let barkup=""
	if get(g:Project,"root",'')==''
		try
			call s:ToggleMain()
			let barkup=g:Project.current.main
			let g:Project.current.main=''
		catch /.*/
			throw "System Initialize Failed: ".v:exception.' at '.v:throwpoint.' '
		endtry
	endif
	call s:ReadProjectConfigFile()
	let currentType=s:GetCurrentType()
	let currentmainfile=get(get(g:Project,currentType,{}),'main','')
	let typename=s:GetProjectScript()
	let typename=typename==""?fnamemodify(bufname("%"),":e"):fnamemodify(typename,":t:r")
	let typemainfile=get(get(g:Project,typename,{}),'main','')
	if !filereadable(typemainfile) && !filereadable(currentmainfile)
		let manager=s:GetProjectManager()
		if manager==""
			if barkup==""
				call s:ToggleMain()
			else
				execute 'runtime! development/'.currentType.'.vim'
				call s:DefaultInitProject()
				call g:InitProject()
				let g:Project.current.main=barkup
			endif
		else
			call s:SetCurrentType(manager)
			if barkup!=''
				let barkup=barkup.' is no longer the main file.'
				call g:EchoWarningMsg(barkup." Using ".manager." project manager tool instead")
			endif
			if get(t:,manager."_keepconfigfile",1)>0
				call s:WriteProjectConfigFile()
			endif
		endif
		return
	endif
	if typename!=""
		if !filereadable(typemainfile) || get(t:,typename."_keepmain",1)==0
			if match(split(g:ProjectManager,':'),'^'.currentType.'$')>-1
				return
			endif
			try
				call s:ToggleMain()
				return
			catch /.*Unknown Type.*/
				call g:EchoErrorMsg(v:exception)
			endtry
		else
			call s:SetCurrentType(typename)
			return
		endif
	endif
	if get(t:,typename."_keepmain",1)==0
		throw "Confusion Project!"
	endif
	call s:SetCurrentType(currentType)
endfunction

function! g:ParseCommand(cmd)
	try
		let cmds=split(a:cmd,' ')
		return g:Trim(join(filter(map(cmds,'g:ParseOption(v:val,cmds[0])'),'v:val!=""'),' '))
	catch /.*/
		call g:EchoErrorMsg("Fail to parse the command: ".v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

function! g:ParseOption(option,cmd)
	if a:option=='COMPILEOPTIONS'
		return substitute(g:Project.current.extraoption.compiler,'<=>',' ','g')
	elseif a:option=='EXECUTEOPTIONS'
		return substitute(g:Project.current.extraoption.interpreter,'<=>',' ','g')
	elseif a:option=='ARGUMENTS'
		return g:Project.current.extraoption.program
	elseif a:option=='PROJECTROOT'
		return g:Project.root
	elseif a:option=='TARGET'
		try
			return function('g:Get_'.s:GetCurrentType().'_TARGET_value')(a:cmd,'TARGET')
		catch /.*/
			return g:Project[s:GetCurrentType()]["main"]
		endtry
	elseif a:option=="PROGRAM"
		return g:TranslateToExecutor(g:Project.current.main==""?bufname("%"):g:Project.current.main)
	end

	let keywordsign=&iskeyword
	set iskeyword+=_
	let optvar=matchstr(a:option,'\[\k\+\]')[1:-2]
	if optvar==''
		let optvar=matchstr(a:option,'{.\+}')[1:-2]
		if optvar==''
			let &iskeyword=keywordsign
			return a:option
		endif
		let optval=get(g:Project.current.variable,optvar,get(g:Project,optvar,''))
		if optval==''
			try
				let optval=eval(optvar)
			catch /.*/
				let optval=optvar
			endtry
		endif
		let &iskeyword=keywordsign
		return substitute(a:option,'{'.optvar.'}',optval,'g')
	endif
	let optopt=g:GetDefinitionSign(optvar,4,' ')
	let optspt=g:GetDefinitionSign(optvar,5,':')
	let optevn=g:GetDefinitionSign(optvar,6,'')
	let optval=""
	try
		let optnam=substitute(a:option,'\[\k\+\].*$','','g')
		let optval=function('g:Get_'.s:GetCurrentType().'_'.optvar.'_value')(a:cmd,optnam)
	catch /.*/
		let optval=g:GetOptionValue(optvar,optevn)
	endtry
	let optrst=(optspt=='M')?join(map(split(optval,':'),"substitute(a:option,'\\[\\k\\+\\]',optopt.v:val,'g')"),' '):(optval==""?"":substitute(a:option,'\[\k\+\]',optopt.substitute(optval,":",optspt,'g'),'g'))
	let &iskeyword=keywordsign
	return optrst
endfunction

function! g:GetOptionValue(var,evn,...)
	let varval=get(g:Project.current.variable,a:var,get(g:Project,a:var,''))
	if g:GetDefinitionSign(a:var,2)=='v'
		return varval
	endif

	let vardef=get(g:Project.current.definition,a:var,'')
	execute 'let result=substitute($'.a:evn.',";",":","g")'
	if vardef=="" || varval==""
		return g:FilterOptionValue(result)
	endif
	
	let keywordsign=&iskeyword
	set iskeyword+=_
	if a:0>0?a:000[0]:1
		let varvalnew=''
		for value in split(varval,":")
			let unixpath=substitute(value,'\','/','g')
			if unixpath=~'^\([./]\)\|\(\k:/\)'
				let varvalnew=varvalnew.":".fnamemodify(value,":p")
			else
				let varvalnew=varvalnew.":".fnamemodify(g:Project.root."/".value,":p")
			endif
		endfor
		let varval=varvalnew
	endif
	let &iskeyword=keywordsign

	if g:GetDefinitionSign(a:var,2)=~'^[df]'
		return g:FilterOptionValue(varval.':'.result)
	endif

	try
		let suffixes=split(split(vardef,'/')[1],':')[1:-1]
		for element in split(varval,":")
			for suffix in suffixes
				let elements=filter(split(glob(element.'/*'),'\n'),"filereadable(v:val)")
				let result=join(filter(elements,"fnamemodify(v:val,':e')=~?'^'.suffix.'$'"),":").':'.result
			endfor
		endfor
	catch /.*/
		call g:EchoErrorMsg("Variable parsed failed: ".a:var)
	endtry
	return g:FilterOptionValue(result)
endfunction

function! g:FilterOptionValue(value)
	let result=g:Trim(a:value)
	let lists=map(filter(split(result,':'),'v:val!="" && g:FileExists(v:val)'),'resolve(v:val)')
	let result=join(filter(lists,'match(lists,"^".v:val."$",0,2)==-1'),':')
	if match(result,'\.\/:')>0
		let result='./:'.substitute(result,'\.\/:','','g')
	endif
	return substitute(result,'\/$','','g')
endfunction

function! g:RegisterFunction(var,function)
	try
		if exists(a:var)
			execute "unlet ".a:var
		endif
		execute "let ".a:var."=function('".a:function."')"
	catch /.*/
		call g:EchoErrorMsg(a:function." Register failed: ".v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

" Other Private Functions
function! s:GetProjectScript()
	let filename=fnamemodify(bufname("%"),":p")
	let scripts=[]
	let shs=[]
	for eachruntime in split(&runtimepath,',')
		let prefix=eachruntime.'/development/'
		call add(scripts,resolve(prefix.fnamemodify(filename,":e").'.vim'))
		call add(scripts,resolve(prefix.&filetype.'.vim'))
		call add(shs,resolve(prefix.'sh.vim'))
	endfor
	call filter(filter(scripts,'filereadable(v:val)'),'match(scripts,"^".v:val."$",0,2)==-1')
	call filter(filter(shs,'filereadable(v:val)'),'match(shs,"^".v:val."$",0,2)==-1')
	if len(scripts)==0
		if match(readfile(filename,'',20),'^\s*#!')==-1
			return ''
		endif
		let scripts=shs
	endif
	if get(g:Project,"current",{})!={}
		let index=match(scripts,s:GetCurrentType().'.vim$')
		if index>=0
			return scripts[index]
		endif
	endif
	let size=len(scripts)
	if size>1
		let index=0
		for eachtype in scripts
			echo index.': '.fnamemodify(eachtype,":t:r")
			let index=index+1
		endfor
		let selected=input("Too many matched items, please select:[0] ")
		return scripts[selected>=size?(size-1):selected]
	endif
	return scripts[0]
endfunction

function! s:AllocateSpace(project)
	let g:Project[a:project]={}
	let g:Project[a:project]['definition']={}
	let g:Project[a:project]['variable']={}
	let g:Project[a:project]['command']={}
	let g:Project[a:project]['extraoption']={'compiler':'','interpreter':'','program':'','builder':''}
	let g:Project[a:project]['main']=''
	let g:Project[a:project]['build']=get(t:,a:project.'_build','')
	call garbagecollect()
endfunction

function! s:MergeConfiguration(project)
	let keywordsign=&iskeyword
	set iskeyword+=_
	call s:AllocateSpace(a:project)
	for [var,value] in items(filter(deepcopy(t:),'v:key=~"^".a:project."_\\k*_definition$"'))
		let varparts=split(var,'_')
		if len(varparts)<3
			call g:EchoErrorMsg("Invalid variable name: ".var)
			continue
		endif
		let g:Project[a:project]['definition'][join(varparts[1:-2],'_')]=value
		call s:CheckDefinition(var,value)
	endfor

	for [var,value] in items(filter(deepcopy(t:),'v:key=~"^".a:project."_\\k*_command$"'))
		let varparts=split(var,'_')
		if len(varparts)<3
			call g:EchoErrorMsg("Invalid variable name: ".var)
			continue
		endif
		let g:Project[a:project]['command'][join(varparts[1:-2],'_')]=value
	endfor
	let &iskeyword=keywordsign
endfunction

function! s:CheckDefinition(variable,definition)
	if a:definition!~'/[ro]/[dfiv]\(:.*\)*/[sm]\(/.\+\)*'
		call g:EchoErrorMsg("Invalid definition format: ".a:variable.'='.a:definition)
	endif
endfunction

function! s:ToggleMain()
	try
		write
	catch /.*/
		call g:EchoErrorMsg("Save failed: ".v:exception.' at '.v:throwpoint.' ')
	endtry
	let filename=bufname('%')
	let typescript=s:GetProjectScript()
	if typescript==""
		throw "Unknown Type: ".fnamemodify(filename,":e")
	endif

	let typename=fnamemodify(typescript,":t:r")
	let origtype=s:GetCurrentType()
	if origtype!=typename
		call g:DeposeProject()
		execute "source ".typescript
		call s:DefaultInitProject()
		call g:InitProject()
	endif
	
	if get(t:,typename."_keepmain",1)==0 && has_key(g:Project,typename)
		if type(g:Project[typename])!=4
			call s:SetCurrentType(origtype)
			throw "The project type and the variable are in conflict!"
		endif
		let g:Project[typename]['main']=""
	endif
	let cmf=fnamemodify(filename,":p")
	if get(get(g:Project,typename,{}),'main','')==cmf
		call g:EchoWarningMsg(g:Project.current.main.' is no longer the main file for '.typename.'.')
		let g:Project[typename]['main']=""
	elseif g:CheckMain(typename,cmf)==1
		call s:MergeConfiguration(typename)
		call s:SetCurrentType(typename)
		let g:Project.current.main=cmf
		call s:InitEnvironment()
		call g:EchoMoreMsg(cmf.' is set as the main file for '.typename.'.')
	else
		call s:SetCurrentType(origtype)
		throw 'Main file checked fail!'
	endif
endfunction

function! s:GetCurrentType()
	if get(g:Project,"current",{})=={}
		return ""
	endif
	for typename in sort(filter(keys(g:Project),'type(g:Project[v:val])==4 && v:val!="current"'))
		if g:Project.current==g:Project[typename]
			return typename
		endif
	endfor
	return ""
endfunction

function! s:SetCurrentType(typename)
	if a:typename==''
		call g:EchoWarningMsg("Empty project name, the current project dose not change!")
		return
	endif
	if has_key(g:Project,a:typename)==0
		call s:AllocateSpace(a:typename)
	endif
	if type(g:Project[a:typename])!=4
		throw "The project name and the variable are in conflict: ".a:typename
	endif
	let g:Project.current=g:Project[a:typename]
endfunction

function! s:GetProjectManager()
	for manager in split(g:ProjectManager,":")
		let possible=map(split(&runtimepath,','),'resolve(v:val."/development/".manager.".vim")')
		call filter(filter(possible,'filereadable(v:val)'),'match(possible,"^".v:val."$",0,2)==-1')
		if len(possible)>0 && s:CheckForProjectManager(manager)==1
			return manager
		endif
	endfor
	return ""
endfunction

function! s:CheckForProjectManager(project)
	call g:DeposeProject()
	execute 'runtime! development/'.a:project.'.vim'
	call s:DefaultInitProject()
	call g:InitProject()
	let buildfiles=[]
	for config in split(get(t:,a:project."_default",""),':')
		let configfile=g:Project.root.'/'.config
		if filereadable(configfile) && g:CheckMain(a:project,configfile)==1
			call add(buildfiles,configfile)
		endif
	endfor
	let size=len(buildfiles)
	if size==0
		return 0
	endif
	if get(g:Project,a:project,{})=={}
		call s:MergeConfiguration(a:project)
	endif
	let mainfile=buildfiles[0]
	if size>1
		let index=0
		for eachtype in buildfiles
			echo index.': '.fnamemodify(eachtype,":t:r")
			let index=index+1
		endfor
		let selected=input("Too many build files, please select:[0] ") 
		let mainfile=buildfiles[selected>=size?(size-1):selected]
	endif
	let g:Project[a:project]['main']=mainfile
	return 1
endfunction

" Ex command which take 0 or more ( up to 20 ) parameters
function! g:ExecuteCommand(...)
	if a:0==0
		call g:EchoWarningMsg(s:GetCmdPreffix()." <NOTHING TO EXECUTE>")
		return
	endif

	try
		let parms=map(deepcopy(a:000),'g:Trim(v:val)')
		let msg=join(parms,' ')
		let cmd=join(map(parms,'substitute(expand(v:val),"\n"," ","g")'),' ')
		if msg=~'^\s*>*\s*:'
			let msg=substitute(msg,'^\s*>*\s*','','g')
			call g:EchoMoreMsg(s:GetCmdPreffix().msg)
			execute msg
		else
			call s:ExecuteShell(msg,cmd)
		endif
	catch /.*/
		call g:EchoErrorMsg(v:exception.' at '.v:throwpoint.' ')
	endtry
endfunction

function! s:GetCmdPreffix()
	return "[".substitute(strftime("%T"),':','.','g')."@".fnamemodify(getcwd(),":~").":".fnamemodify(bufname('%'),":.")."] "
endfunction

function! s:ExecuteShell(shellmsg,shellcmd)
	let shellcmd=a:shellcmd
	let rein=''
	if match(a:shellmsg,'^\s*>>\s*')==0
		let shellcmd=substitute(shellcmd,'^\s*>>\s*','','g')
		if !filereadable('.VIM_STD_IN')
			call writefile([],'.VIM_STD_IN')
		endif
		let rein=' 0<.VIM_STD_IN'
	elseif match(a:shellmsg,'^\s*>\s*')==0
		let shellcmd=substitute(shellcmd,'^\s*>\s*','','g')
		if !filereadable('.VIM_STD_IN')
			let choice=confirm("Input-file not found, give now?","&Yes\n&No",1)
			if choice!=1
				call g:EchoWarningMsg("Missing inputs which are required, The application may be aborted!")
				call writefile([],'.VIM_STD_IN')
			else
				echo 'Pease give the inputs line by line util "EOF" given.'
				let lines=[]
				let line=input("")
				while line != "EOF"
					call add(lines,line)
					let line=input("")
				endwhile
				call writefile(lines,'.VIM_STD_IN')
			endif
		endif
		let rein=' 0<.VIM_STD_IN'
	endif
	
	let cmd=s:GetCmdPreffix().shellcmd
	let s:CurrentCommandResult=''
	call g:EchoMoreMsg(cmd)
	try
		if shellcmd=~'^\s*cd '
			execute shellcmd
		else
			let s:CurrentCommandResult=system('cd '.getcwd().' && '.shellcmd.rein)
		endif
	catch /.*/
		let s:CurrentCommandResult=v:exception.' at '.v:throwpoint."\n"
	endtry
	if v:shell_error!=0
		let error="ExecuteCommand failed: shell exit code ".v:shell_error
		let s:CurrentCommandResult.=((s:CurrentCommandResult=~'\n$')?"":"\n").error."\n"
		call g:EchoWarningMsg(error)
	endif

	try
		execute "compiler ".shellcmd[0:match(shellcmd,' ')]
		cexpr cmd."\n".s:CurrentCommandResult
	catch /.*E666.*/
		caddexpr cmd."\n".s:CurrentCommandResult
	endtry
	let this=bufwinnr("%")
	copen 8
	normal G
	execute this."wincmd w"
endfunction

function! g:Trim(str)
	return substitute(a:str,'\(^\s*\)\|\(\s*$\)','','g')
endfunction

function! g:FileExists(file)
	return isdirectory(resolve(a:file)) || filereadable(resolve(a:file))
endfunction

" Highlight echo
function! g:EchoErrorMsg(msg)
	echohl ErrorMsg
	echo a:msg
	echohl None
endfunction

function! g:EchoWarningMsg(msg)
	echohl WarningMsg
	echomsg a:msg
	echohl None
endfunction

function! g:EchoMoreMsg(msg)
	echohl MoreMsg
	echomsg a:msg
	echohl None
endfunction

call s:DefaultInitProject()
