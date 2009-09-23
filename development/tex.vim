" Vim development plugin for tex
" Version: 3.0
" Maintainer: WarGrey <juzhenliang@gmail.com>
" Last Change: 2009 May 04
"

if exists("b:tex_development_loaded") && b:tex_development_loaded==1
	finish
endif
let b:tex_development_loaded=1

function! g:TexInitProject()
    call g:RegisterFunction("g:TranslateToExecutor","g:TexTranslateToExecutor")
	
	let t:tex_source_definition="/r/d/s/"
	let t:tex_destination_definition="/r/d/s/=/"
	let t:tex_otherfiles_definition="/o/i:log:aux:out:toc/m/ /M/"

	let output="doc:documentation"
	let xelatex="xelatex -output-directory[destination] TARGET"

	let t:tex_source_candidacy="doc_src:tex_src"
	let t:tex_destination_candidacy=output
	let t:tex_otherfiles_candidacy=output

	let t:tex_compile_command=xelatex
	let t:tex_xelatex_command=xelatex
	let t:tex_latex_command="latex -output-directory[destination] -output-format=pdf TARGET"
	let t:tex_interpret_command="okular PROGRAM &"
	let t:tex_clean_command="rm -fr [otherfiles]"

	let t:tex_build='xelatex:xelatex:interpret:clean'
	let t:tex_suffixes='tex'
endfunction

function! g:TexTranslateToExecutor(src)
	let dest=split(g:GetOptionValue('destination',''),":")[0]
	return dest.'/'.fnamemodify(g:ParseOption('TARGET','interpret'),":t:r").'.pdf'
endfunction

call g:RegisterFunction("g:InitProject","g:TexInitProject")
