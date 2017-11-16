.. default-role:: code

###############################################
 Info.vim: Read and navigate Info files in Vim
###############################################

Info.vim provides  two features:  syntax highlighting  for Info files generated
from Texinfo,  and it implements a  reader for browsing and  navigating through
Info files installed on the user's system.

Info  is the  file  format  of the  `info`  command-line  program  and  Emacs's
Info-mode.  This format is most  often generated from Texinfo  source files and
used for software documentation.  Texinfo is the official  documentation format
of GNU. Check out this asciicast for a live demonstation:

.. image:: https://asciinema.org/a/92884.png
   :width: 75%
   :align: center
   :target: https://asciinema.org/a/92884


Installation
############

Install it like any other Vim plugin. You must have at least version 6.4 of the
GNU Info command-line tool installed on your system (older versions might work,
but I haven't tested them).  You can set the binary  by setting the `g:infoprg`
variable to its path.


Quickstart
##########

This plugin is still very much under construction, so any of this may change in
the future. There is a interactive  tutorial available via `:Info info.vim`. To
open an Info document run

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

   " Display all cross references in location list
   :Follow
   " Follow a named cross-reference
   :Follow Name of the reference

Use the `K` key in normal mode  to follow the reference under the cursor, works
for both menu entries and cross references.


Navigation
==========

Use  the  commands  `:InfoUp`,  `:InfoNext`  and  `:InfoPrev`  to  navigate  to
respective node. Alternatively, add mappings like these to your settings.

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nmap <buffer> gu <Plug>(InfoUp)
       nmap <buffer> gn <Plug>(InfoNext)
       nmap <buffer> gp <Plug>(InfoPrev)
   endif

You   can  access   the  menu   via  the   `:InfoMenu`  command.   It  supports
tab-completion, and if  no argument is given  all menu items are  listed in the
location list. If  you want a prompt  similar to standalone Info  use a mapping
like this:

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nmap <buffer> gm <Plug>(InfoMenu)
   endif

You can follow a cross-reference using the `:InfoFollow` command. You can remap
the prompt to something more convenient:

.. code-block:: vim

   " Only apply the mapping to generated buffers
   if &buftype =~? 'nofile'
       nmap <buffer> gf <Plug>(InfoFollow)
   endif


Stuff left to do
################

The goal for the first  stable release is feature-parity  with standalone Info.
These features depend on support from standalone Info, so my hands are tied for
the time being.

- Index lookup (`:Index` command)
- Search within a file (`:Search` command)
- Going  to a  specific node  in the file  (`:Goto` command)  (implemented, but
  without tab-completion)
