" Vim development plugin for flash project
" Version: 2.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 Sep 06
"

if exists("b:matlab_development_loaded") && b:matlab_development_loaded==1
	finish
endif
let b:matlab_development_loaded=1

function! g:MatlabInitProject()
    call g:RegisterFunction("g:TranslateToExecutor","g:MatlabTranslateToExecutor")

	let t:matlab_mlint_command="mlint -id -notok -eml -cyc PROGRAM"
	let t:matlab_compile_command=t:matlab_mlint_command
	let t:matlab_interpret_command="matlab -nosplash -nodesktop EXECUTEOPTIONS"

	let t:matlab_build="mlint:interpret"
	let t:matlab_suffixes="m:M"
endfunction

function! g:Do_matlab_compile()
	call g:Do_matlab_mlint()
endfunction

function! g:Do_matlab_interpret()
	let arguments='('.substitute(g:ParseCommand("ARGUMENTS"),' ',',','g').')'
	let maincmd=fnamemodify(g:Project.current.main,":t:r").substitute(arguments,'^()$','','g')
	let matlabcmds=[]
	call add(matlabcmds,"cd ".fnamemodify(bufname("%"),":p:h"))
	call add(matlabcmds,maincmd)
	call add(matlabcmds,"display(' ')")
	call add(matlabcmds,"while get(0,'CurrentFigure'),")
	call add(matlabcmds,"uiwait(get(0,'CurrentFigure'))")
	call add(matlabcmds,'end')
	try
		call writefile(matlabcmds,'.MATLABIN')
		let launcher=g:ParseCommand(get(g:Project.current.command,'interpret',""))
		call g:ExecuteCommand(launcher,'0<.MATLABIN','1>.MATLABOUT','2>.MATLABERR','&')
		
		while 1
			let stdout=readfile('.MATLABOUT')
			let head=match(stdout,'^>> >> ')
			if head==-1
				continue
			elseif !exists('startpos')
				let startpos=head
				call g:AddShellCommandResult(['>> '.maincmd,''])
				call g:DisplayOutput()
			endif
			
			let stdout[head]=substitute(g:Trim(stdout[head][5:-1]),'\(>>\s*\)*$','','g')
			let endpos=len(stdout)-2
			if (endpos>=startpos)
				call g:AddShellCommandResult(stdout[startpos :endpos]+[''])
				call g:DisplayOutput()
				let startpos=endpos+1
			endif
			if g:Trim(stdout[-1])=~'^>>$'
				break
			endif
		endwhile
		
		let H=nr2char(8)
		let stderr=join(filter(readfile('.MATLABERR'),'len(v:val)>len("")')," ")
		let startpos=match(stderr,'{'.H.'???',0)
		while startpos>=0
			let endpos=match(stderr,'}'.H,startpos)
			call g:AddShellCommandResult(["ExecuteCommand failed: ".stderr[startpos+6:endpos-2],''])
			let startpos=match(stderr,'{'.H.'???',endpos)
		endwhile
		call g:DisplayOutput()
	finally
		call delete('.MATLABIN')
		call delete('.MATLABOUT')
		call delete('.MATLABERR')
	endtry
endfunction

function! g:Do_matlab_mlint()
	call g:ExecuteCommand(g:ParseCommand(get(g:Project.current.command,'mlint',"")))
	let qfix={'filename':bufname("%"),'lnum':0,'col':0,'vcol':0,'nr':-1,'text':''}
	let quickfixes=[]
	let hasError=0
	for line in split(@+,"\n")
		if g:Trim(line)==''
			continue
		endif
	    if match(line,'^\(=\{10}\) .\+ \1$')>-1
			let qfix['filename']=match(line,'[^= ]\+')
			continue
		endif
		let qfix['lnum']=matchstr(line,'^L \d\+')[2:-1]
		let qfix['col']=matchstr(line,'(C \d\+')[3:-1]
		let qfix['text']=matchstr(line,'): \u\+:.*$')[3:-1]
		call add(quickfixes,copy(qfix))
	endfor
	call setqflist(quickfixes)
	cc!
endfunction

function! g:MatlabTranslateToExecutor(sourcefile)
	return fnamemodify(a:sourcefile,":p")
endfunction

call g:RegisterFunction("g:InitProject","g:MatlabInitProject")
