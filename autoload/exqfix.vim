" variables {{{1
let s:cur_qfix_file = "" 

let s:zoom_in = 0
let s:keymap = {}

let s:help_open = 0
let s:help_text_short = [
            \ '" Press <F1> for help',
            \ '',
            \ ]
let s:help_text = s:help_text_short
" }}}

" functions {{{1

" exqfix#bind_mappings {{{2
function exqfix#bind_mappings()
    call ex#keymap#bind( s:keymap )
endfunction

" exqfix#register_hotkey {{{2
function exqfix#register_hotkey( priority, local, key, action, desc )
    call ex#keymap#register( s:keymap, a:priority, a:local, a:key, a:action, a:desc )
endfunction

" exqfix#toggle_help {{{2

" s:update_help_text {{{2
function s:update_help_text()
    if s:help_open
        let s:help_text = ex#keymap#helptext(s:keymap)
    else
        let s:help_text = s:help_text_short
    endif
endfunction

function exqfix#toggle_help()
    if !g:ex_qfix_enable_help
        return
    endif

    let s:help_open = !s:help_open
    silent exec '1,' . len(s:help_text) . 'd _'
    call s:update_help_text()
    silent call append ( 0, s:help_text )
    silent keepjumps normal! gg
    call ex#hl#clear_confirm()
endfunction

" exqfix#open {{{2
function exqfix#open(filename)
    " if the filename is empty, use default project file
    let filename = a:filename
    if filename == ""
        let filename = g:ex_qfix_file
    endif

    " if we open a different project, close the old one first.
    if filename !=# s:cur_qfix_file
        if s:cur_qfix_file != ""
            let winnr = bufwinnr(s:cur_qfix_file)
            if winnr != -1
                call ex#window#close(winnr)
            endif
        endif

        " reset project filename and title.
        let s:cur_qfix_file = a:filename
    endif

    " open and goto the window
    call exqfix#open_window()
endfunction

" exqfix#open_window {{{2

function exqfix#init_buffer()
    " NOTE: ex-project window open can happen during VimEnter. According to  
    " Vim's documentation, event such as BufEnter, WinEnter will not be triggered
    " during VimEnter.
    " When I open exqfix window and read the file through vimentry scripts,
    " the events define in exqfix/ftdetect/exqfix.vim will not execute.
    " I guess this is because when you are in BufEnter event( the .vimentry
    " enters ), and open the other buffers, the Vim will not trigger other
    " buffers' event 
    " This is why I set the filetype manually here. 
    set filetype=exqfix
    au! BufWinLeave <buffer> call <SID>on_close()

    if line('$') <= 1 && g:ex_qfix_enable_help
        silent call append ( 0, s:help_text )
        silent exec '$d'
    else
        silent loadview
    endif
endfunction

function s:on_close()
    let s:zoom_in = 0
    let s:help_open = 0
    silent mkview

    " go back to edit buffer
    call ex#window#goto_edit_window()
endfunction

function exqfix#open_window()
    let winnr = winnr()
    if ex#window#check_if_autoclose(winnr)
        call ex#window#close(winnr)
    endif
    call ex#window#goto_edit_window()

    if s:cur_qfix_file == ""
        let s:cur_qfix_file = g:ex_qfix_file
    endif

    let winnr = bufwinnr(s:cur_qfix_file)
    if winnr == -1
        call ex#window#open( 
                    \ s:cur_qfix_file, 
                    \ g:ex_qfix_winsize,
                    \ g:ex_qfix_winpos,
                    \ 0,
                    \ 1,
                    \ function('exqfix#init_buffer')
                    \ )
    else
        exe winnr . 'wincmd w'
    endif
endfunction

" exqfix#toggle_window {{{2
function exqfix#toggle_window()
    let result = exqfix#close_window()
    if result == 0
        call exqfix#open_window()
    endif
endfunction

" exqfix#close_window {{{2
function exqfix#close_window()
    if s:cur_qfix_file != ""
        let winnr = bufwinnr(s:cur_qfix_file)
        if winnr != -1
            call ex#window#close(winnr)
            return 1
        endif
    endif
    return 0
endfunction

" exqfix#toggle_zoom {{{2
function exqfix#toggle_zoom()
    if s:cur_qfix_file != ""
        let winnr = bufwinnr(s:cur_qfix_file)
        if winnr != -1
            if s:zoom_in == 0
                let s:zoom_in = 1
                call ex#window#resize( winnr, g:ex_qfix_winpos, g:ex_qfix_winsize_zoom )
            else
                let s:zoom_in = 0
                call ex#window#resize( winnr, g:ex_qfix_winpos, g:ex_qfix_winsize )
            endif
        endif
    endif
endfunction

" exqfix#confirm_select {{{2
" modifier: '' or 'shift'
function exqfix#confirm_select(modifier)
     " TODO
endfunction
" }}}1

" vim:ts=4:sw=4:sts=4 et fdm=marker:
