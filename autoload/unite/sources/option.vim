scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


" let s:V = vital#of("vital")
let s:V = vital#unite_option#of()
let s:L = s:V.import("Data.List")
let s:S = s:V.import("Data.String")



function! s:get_quickref()
" 	return get(split(globpath(&rtp, "doc/quickref.*"), "\n"), 2, "")
	return get(split(globpath(&rtp, "doc/quickref.*"), "\n"), 0, "")
endfunction


function! s:parse_optionline(line)
	let data = matchlist(a:line, '^''\(\w\{-}\)''\s\{-}''\(\w\{-}\)''\s\{-}\(.*\)$')[1:]
	if empty(data)
		let data = matchlist(a:line, '^''\(\w\{-}\)''\s\{-}\(.*\)$')[1:]
	endif
	let data = map(filter(data, "!empty(v:val)"), 's:S.trim(v:val)')
	if len(data) == 2
		call insert(data, "", 1)
	endif
	return {
\		"name"        : s:S.replace(data[0], "'", ""),
\		"short_name"  : s:S.replace(data[1], "'", ""),
\		"description" : data[2]
\	}
endfunction


function! s:get_options(...)
	let ref = get(a:, 1, s:get_quickref())
	if !filereadable(ref)
		return []
	endif
	let file = readfile(ref)
	let start = s:L.find_index(file, 'v:val =~ ''*option-list*'' ') + 1
	let end   = s:L.find_index(file, 'v:val == ''------------------------------------------------------------------------------''  ', start) - 1
	let data = file[start : end]
" 	let data = file[start : start + 10]

	for lnum in range(0, len(data)-1)
		if data[lnum] =~ '^\s'
			let data[lnum-1] .= s:S.trim(data[lnum])
			let data[lnum] = ""
		endif
	endfor
	call filter(data, "!empty(v:val)")

	return map(data, "s:parse_optionline(v:val)")
endfunction


let s:source = {
\	"name" : "option",
\	"description" : "Vim options",
\	"action_table" : {
\		"edit" : {
\			"is_selectable" : 0,
\			"description" : "Edit option",
\		},
\		"preview" : {
\			"is_selectable" : 0,
\			"is_quit" : 0,
\			"description" : "Preview help option",
\		},
\	},
\}


function! s:input(...) abort
  new
  cmap <buffer> <esc> __CANCELED__<cr>
  let ret = call('input', a:000)
  bw!
  redraw
  if ret =~ '__CANCELED__$'
	  return "\<Esc>"
  endif
  return ret
endfunction


function! s:source.action_table.edit.func(candidate)
	let name = a:candidate.action__option_name
	let result = s:input("let &" . name . "=", eval("&".name))
	if result == "\<Esc>"
		echo "Canceled."
		return
	endif
	let cmd = "let &" . name . "=" . result
	call histadd(":", cmd)
endfunction


function! s:source.action_table.preview.func(candidate)
	keepjump execute ":help" a:candidate.action__option_name
	execute "normal! \<C-w>p"
endfunction


function! s:source.gather_candidates(args, context)
	let options = s:get_options()
	let max_size = len(s:L.max_by(options, "strlen(v:val.name)").name)
	return map(options, '{
\		"word" : s:S.pad_right(v:val.name, max_size) . " : " . v:val.description,
\		"kind" : "command",
\		"action__command" : "help " . v:val.name,
\		"action__option_name" : v:val.name,
\	}')
endfunction




function! unite#sources#option#define()
	return s:source
endfunction


if expand("%:p") == expand("<sfile>:p")
	call unite#define_source(s:source)
endif


let &cpo = s:save_cpo
unlet s:save_cpo
