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
	let t:ant_all_command="ant -buildfile TARGET all"
	let t:ant_install_command="ant -buildfile TARGET install"
	let t:ant_uninstall_command="ant -buildfile TARGET uninstall"
	let t:ant_install_strip_command="ant -buildfile TARGET install-strip"
	let t:ant_clean_command="ant -buildfile TARGET clean"
	let t:ant_distclean_command="ant -buildfile TARGET distclean"
	let t:ant_mostlyclean_command="ant -buildfile TARGET mostlyclean"
	let t:ant_maintainer_clean_command="ant -buildfile TARGET maintainer-clean"
	let t:ant_TAGS_command="ant -buildfile TARGET TAGS"
	let t:ant_info_command="ant -buildfile TARGET info"
	let t:ant_dvi_command="ant -buildfile TARGET dvi"
	let t:ant_dist_command="ant -buildfile TARGET dist"
	let t:ant_check_command="ant -buildfile TARGET check"
	let t:ant_installcheck_command="ant -buildfile TARGET installcheck"
	let t:ant_installdirs_command="ant -buildfile TARGET installdirs"
	let t:ant_compile_command="ant -buildfile TARGET compile"
	let t:ant_interpret_command="ant -buildfile TARGET interpret"
	
	let t:ant_build='all'
	let t:ant_suffixes='xml'
	let t:ant_default='build.xml'
endfunction
	
call g:RegisterFunction("g:InitProject","g:AntInitProject")
