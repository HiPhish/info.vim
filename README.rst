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

   At the moment info.vim is still *very* early work in progress. Browsing info
   files is  implemented,  but not  node navigation.  You can  test the  syntax
   highlighting of manually  opened info files at the  moment or open documents
   by topic.


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

   nnoremap <buffer> gn :Node -next<CR>
   nnoremap <buffer> gp :Node -previous<CR>
   nnoremap <buffer> gu :Node -up<CR>

.. note::

   The `:Toc` and `:Node` are only  defined for info buffers, other plugins can
   implement them for other file types without stepping on info.vim's toes.


Stuff left to do
################

It should be  possible to  directly jump  to a node  by calling  `:Info <topic>
<node>` and the URI  should similarly allow  specifying a node  after the topic
`info://<topic>/<node>`. We also need to the able to recognise when the user is
having  their  cursor inside  a reference  and allow  jumping to  that node  by
pressing `K`.
