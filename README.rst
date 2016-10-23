.. default-role:: code

##################################################
 info.vim  -- Read and navigate Info files in Vim
##################################################

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


Usage
#####

This plugin is still very much under construction, so any of this may change in
the future. To open an info document run

.. code-block::

   :Info <topic>

The placeholder `topic` is the topic you want to read about,  e.g. `:Info bash`
to read the manual for the Bourne Again Shell.  Alternatively you can also open
a buffer with a URI pattern like this:

.. code-block::

   :edit info://<topic>

You could call `:e info://bash` in a buffer to open the same document as above.
Specifying nodes is not implemented yet.
