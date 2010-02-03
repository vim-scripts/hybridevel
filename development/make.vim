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
	let t:make_all_command="make COMPILEOPTIONS all"
	let t:make_install_command="make COMPILEOPTIONS install"
	let t:make_uninstall_command="make COMPILEOPTIONS uninstall"
	let t:make_install_strip_command="make COMPILEOPTIONS install-strip"
	let t:make_clean_command="make COMPILEOPTIONS clean"
	let t:make_distclean_command="make COMPILEOPTIONS distclean"
	let t:make_mostlyclean_command="make COMPILEOPTIONS mostlyclean"
	let t:make_maintainer_clean_command="make COMPILEOPTIONS maintainer-clean"
	let t:make_TAGS_command="make COMPILEOPTIONS TAGS"
	let t:make_info_command="make COMPILEOPTIONS info"
	let t:make_dvi_command="make COMPILEOPTIONS dvi"
	let t:make_dist_command="make COMPILEOPTIONS dist"
	let t:make_check_command="make COMPILEOPTIONS check"
	let t:make_installcheck_command="make COMPILEOPTIONS installcheck"
	let t:make_installdirs_command="make COMPILEOPTIONS installdirs"
	let t:make_compile_command="make COMPILEOPTIONS compile"
	let t:make_interpret_command="make COMPILEOPTIONS interpret"
	
	let t:make_build='all'
	let t:make_suffixes='mk:mak::dsp'
	let t:make_default="Makefile"
endfunction
	
call g:RegisterFunction("g:InitProject","g:MakeInitProject")
