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

   At the moment info.vim is still *very* early work in progress. You could run
   into some unexpected edge cases.

Installation
############

Install it like  any other Vim plugin.  You must have the GNU info command-line
tool installed on your system, or a compatible alternative.


Quickstart
##########

This plugin is still very much under construction, so any of this may change in
the future. To open an info document run

.. code-block:: vim

   :Info <topic>

The placeholder `topic` is the topic you want to read about,  e.g. `:Info bash`
to read the manual for the Bourne Again Shell.  Alternatively you can also open
a buffer with a URI pattern like this:

.. code-block:: vim

   :edit info://<topic>

You could call `:e info://bash` in a buffer to open the same document as above.


Navigation
==========

Use the `:Toc` command from inside an info buffer to open its table of contents
in the location list. Use the `:Node` command to navigate inside the buffer.

.. code-block:: vim

   " Print the current node
   :Node

   " Jump to node <node> (typed without the angle braces)
   :Node <node>

   " Jump the next node
   :Node -next

   " Jump the previous node
   :Node -previous

   " Jump the parent node
   :Node -up

I recommend mapping the navigation commands to something more convenient.

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nnoremap <buffer> gn :Node -next<CR>
       nnoremap <buffer> gp :Node -previous<CR>
       nnoremap <buffer> gu :Node -up<CR>
   endif

.. note::

   The `:Toc` and `:Node` are only  defined for info buffers, other plugins can
   implement them for other file types without stepping on info.vim's toes.


Stuff left to do
################

- Support for node menus (`:Menu` command)
- Support both short (`* Foo:: bar`) and long (`* Foo: Boo: Baz`) menu items
- Support cross-references (maybe a `:Cross` command as well)
