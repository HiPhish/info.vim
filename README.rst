.. default-role:: code

###############################################
 info.vim: Read and navigate Info files in Vim
###############################################

info.vim provides  two features:  syntax highlighting  for Info files generated
from Texinfo,  and it implements a  reader for browsing and  navigating through
info files installed on the user's system.

Info  is the  file  format  of the  `info`  command-line  program  and  Emacs's
info-mode.  This format is most  often generated from Texinfo  source files and
used for software documentation.  Texinfo is the official  documentation format
of GNU.

.. note::

   At the moment info.vim is still *very* early work in progress. It is not yet
   feature-complete and the interface might change.


Installation
############

Install it like any other Vim plugin. You must have at least version 6.0 of the
GNU info command-line tool installed on your system.  You can set the binary by
setting the `g:infoprg` variable to its path.


Quickstart
##########

This plugin is still very much under construction, so any of this may change in
the future. To open an info document run

.. code-block:: vim

   " Open the directory listing
   :Info
   " Open a particular document
   :Info <file>
   " Same as above, but jump to specific node
   :Info <file> <node>

The placeholder `<file>` is the topic you want to read about, e.g. `:Info bash`
to read the manual for the Bourne Again Shell.  Alternatively you can also open
a buffer with a URI pattern like this:

.. code-block:: vim

   :edit info://
   :edit info://<file>
   :edit info://<file>/<node>

You could call `:e info://bash` in a buffer to open the same document as above.


Navigation
==========

Use the functions `info#next()`,  `info#prev()` and  `info#up()` to navigate to
respective node. I recommend mapping the navigation functions to something more
convenient.

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nnoremap <silent> <buffer> gu :call info#up()<CR>
       nnoremap <silent> <buffer> gn :call info#next()<CR>
       nnoremap <silent> <buffer> gp :call info#prev()<CR>
   endif

I will see to add proper commands later as well.


Stuff left to do
################

The goal for the first stable release is feature-parity with standalone info.

- Menus (`:Menu` command)
- Index lookup (`:Index` command)
- Search within a file (`:Search` command)
- Cross-references (maybe a `:Cross` command as well)
- Support both short (`* Foo:: bar`) and long (`* Foo: Boo: Baz`) menu items
