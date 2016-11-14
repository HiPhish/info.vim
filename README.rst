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

Use the `:Menu` command to follow a node's menu entries.

.. code-block:: vim

   " Display menu in location list
   :Menu
   " Jump to entry 'Introduction'
   :Menu Introduction
   " Short form works as well
   :Menu intro

You can also use tab completion with the `:Menu` command.

You can follow cross-references using the `:Follow` command:

.. code-block:: vim

   " Follow a named cross-reference
   :Follow Name of the reference
   " Follow reference under cursor (works for any kind of reference)
   :Follow


Navigation
==========

Use  the  commands  `:NodeUp`,  `:NodeNext`  and  `:NodePrev`  to  navigate  to
respective node. Alternatively, add mappings like these to your settings.

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nmap <buffer> gu <Plug>InfoUp
       nmap <buffer> gn <Plug>InfoNext
       nmap <buffer> gp <Plug>InfoPrev
   endif

You can access  the menu via the  `:Menu` command.  It supports tab-completion,
and if no argument is given all menu items are listed in the location list.  If
you want a prompt similar to standalone info use a mapping like this:

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nmap <buffer> gm <Plug>InfoMenu
   endif

You can follow a cross-reference using the `:Follow` command.  You can remap it
to something more convenient:

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nmap <buffer> gm <Plug>InfoMenu
   endif


Stuff left to do
################

The goal for the first  stable release is feature-parity  with standalone info.
These features depend on support from standalone info, so my hands are tied for
the time being.

- Index lookup (`:Index` command)
- Search within a file (`:Search` command)
- Going to a specific node in the file (`:Goto` command) (not sure if we really
  need this)
