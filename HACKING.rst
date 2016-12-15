.. default-role:: code

####################################
 Working on the Info plugin for Vim
####################################

This document is intended for programmers who want to work on Info.vim, add new
features,  fix bugs or just  learn how it works and why  certain decisions have
been made. I will assume the reader to be familiar with how Vim plugins work in
general.  All files  follow the  usual directory  hierarchy,  so you  will find
everything where you expect it.


Overview of the plugin design
#############################

The basic idea of Info.vim is to make  Vim a first-class reader for text in the
Info format, just like the standalone Info and Emacs's Info mode. This includes
and is not limited  to finding Info  files in the same  directories as Info and
Emacs do,  skipping to the  beginning o f the first node,  hiding or  replacing
markup information, and offering easy navigation.

Non-goals are the generation or organisation of Info files.  Editing Info files
is no priority,  but should not be inhibited.  Users are themselves responsible
for compiling Info files and deciding where to install them.

The most important aspect is that we are not trying to write another Info.  Vim
is a text editor,  not an  operating system,  our goal is to make  browsing and
reading Info files more pleasant, not to embed an entire program into Vim.  Use
Vim's own features and add as little as possible of your own.  If something can
be achieved with less than five  lines of VimScript then chances are that it is
best left to the user to set.


The Info file format
====================

The following is an informal format description suitable for our needs. An Info
file is a plain-text  file (ASCII or Unicode?) that  contains some light markup
so the reader can  identify parts of it.  Here is a  list of some of  the terms
used, the names are made-up by me because there is no formal specification.

The following representations of ASCII control characters are used:

============  =======  ===========  =======  ==================================
Digraph       Decimal  Hexadecimal  Acronym  Name
============  =======  ===========  =======  ==================================
`^A`                1         0x01      SOH  Start Of Heading
`^H`                8         0x08       BS  Backspace
`^L`               12         0x0C       FF  Form Feed or Page Break
`^M` or `\n`       16         0x0A       LF  Line Feed or Newline
`^_`               31         0x1F       US  Unit Separator
`^?`              127         0x7F      DEL  Delete
============  =======  ===========  =======  ==================================

.. warning::

   Contrary to what is written here nodes do not have to form a tree,  although
   they more often than not do. That part of the document has to be rewritten.


Node
   A node begins with `^_`,  followed by a newline or `^L` and node header (see
   below), and is terminated by either `^_`, `^L` or the end of the file.

   Each file has a root node called `Top` by convention. Each node can directly
   reference any (including none) of the following nodes:  the parent `Up`, and
   the siblings `Next` and `Previous`. Not all of these related nodes exist for
   every node.

Node header
   This line marks  the beginning of a node.  It consists of a  number of `Key:
   Value` pairs where the key is one of `File`,  `Node`, `Next`, `Previous` and
   `Up`. `File` is the first key, the other keys can appear in any order.  Only
   `File` and `Node` are mandatory.

   The keyword is  separated from the value by a colon (`:`),  spaces and tabs.
   The value  is terminated  by a comma,  tabs or  a newline,  but not  spaces,
   spaces count as part of the value (name of the file/node).

   The name of a node can be given as a plain name (e.g. `Definitions`) or with
   the name of a file  prepended in parentheses (e.g. `(bash)Definitions`).  If
   there is no file name, the name of the node is understood to refer to a node
   in the current file. The value of `Node` must not contain a file name.

Menu
   A line that  begins with exactly  `* Menu:` begins a node menu  (the rest of
   that line is a comment).  The purpose of the menu is to list nodes which can
   be reached  from this  node in a  format thats accessible  to human readers.
   Readers can specify the node to jump to by its entry name.

Menu entry
   Each line  which begins  with `* ` is  an entry.  It is  followed by  a name
   readable to humans, `:`,  and the name of the node.  Anything following is a
   comment for humans.  Notice how this is the same `Key: Value` format used in
   the node header line; in addition to a period (`.`) the name of the node can
   also terminated by a tab, comma or newline.

   .. code-block::

      * Human-readable topic: Actual node.    Description.

   The topic terminator  `:` can be followed  by any amount of tabs and spaces.
   If the topic and name of the node are the same a shorthand is preferred:

   .. code-block::

      * Actual node::                        Description.

   Finally,  if the  description matches  `\(line\s+\d+\)` that  line number is
   used as an offset into the node to jump to a particular line of text (offset
   relative to node header).

Node index
   An  index  is a  special  kind  of menu.  The  menu  is preceded  by a  line
   containing only  `^A^H[index^A^H[index]`.

Cross-reference
   These are  essentially hyperlinks,  they specify a  node to jump  to and can
   occur in-line.

   .. code-block::

      *Note Human-readable topic: Actual node.

   This is exactly the  same format as for menu entries,  except that it begins
   with `*Note` or `*note` rather than just `*`.

.. note::

   We don't acutally need the following  features if we read our Info documents
   from an Info compiler like the standalone `info`.

File header
   Some basic information about  the file itself before the first node, such as
   author or license.  Since the header  comes before  any node  it will  no be
   displayed by the reader

Indirect
   If an Info file is split over multiple  files it is necessary to know how to
   find the nodes.  This list contains the partial  files and the offsets which
   need to be subtracted from the global offset when looking for a node.

   .. code-block::

      Indirect:
      <topic>.info-1: 781
      <topic>.info-2: 303374
      <topic>.info-3: 603289
      <topic>.info-4: 901483
      ...

   This list has to come before the tag table.

Tag table
   A table  of tags  occurring at  the end  of the  file along  with their byte
   offsets into the file. A tag can be either a note or a reference. The format
   of the table is as follows:

   .. code-block::

      ^_^L
      Tag Table:
      <node-header>^?<offset>
      ...
      <node-header>^?<offset>
      ^_
      End Tag Table

   Each line of the table contains the beginning of the node's header, followed
   by `^?` and  the offset into  the file in bytes.  If indirection is used the
   first three lines look like this:

   .. code-block::

      ^_^L
      Tag Table:
      (Indirect)

   .. note::

      I have seen files which  begin with `^_` only instead of `^_^L`,  but the
      Info manual says the former is correct.

Emacs local variables
   These are used by Emacs similar to the `vim:...` modeline.

   .. code-block::

      ^_
      Local Variables:
      <variable>: <value>
      End:


The node structure
==================

And Info document  (also called an  Info file)  is made  of nodes.  These nodes
usually form a  tree-like hierarchy,  but this does  not necessarily have to be
the case.  The only truth  is that the  nodes form a  directed graph,  but this
graph may even contain cycles or unreachable nodes.

Each file has  one root node  that's named  `Top` by convention.  The root node
usually has  its first child  as its `Next` node,  but all  other nodes usually
have their next  sibling as their  `Next` and  their previous  sibling as their
`Previous`.

A node can have a menu listing other nodes in it. These nodes can be considered
children of that node,  but don't take that term literally.  It only means that
there is some way for the user to access that node, a child node might not have
the current node as its `Up` node.  In fact,  the child node might even be in a
different file.

The standalone Info program  can access arbitrary nodes  in a file if you use a
recent version (we take version 6.0 to be safe for our purposes).

.. code-block:: sh

   # Will not work in older versions
   info --file 'bash' --node 'What is Bash?'

One special file is the  `dir` file which contains  a menu that maps to all the
other Info files. It's a sort of root of roots if you will.


One format, two purposes
========================

There are  two purposes to  Info files:  reading and writing  them as the plain
text files  they are,  or treating  them as  a complete work  of documentation.
Supporting the former only requires some light support for the syntax.

The latter however is more complex.  Such Info buffers  will not be read from a
file,  instead they will be  generated by reading  the contents  of one or more
files,  assembling  them  into one  buffer,  building a  table of  contents and
replacing or  hiding markup elements.  This is  similar to  how a  plugin would
display manpages.

Both types of buffer have the same type,  but generated buffers need some extra
options set.


The meat and bones of Info.vim
##############################

With the technicalities out of the way let's focus on the actual plugin. I will
skip syntax highlighting,  the syntax code  says it all.  The important code is
found in the following files:

`plugin/info.vim`
   All of the important  code is in here.  The file is *very*  large due to the
   fact that there is  no way in VimScript of  splitting it up without  leaking
   details into the public namespace.

`ftplugin/info.vim`
   File-type settings for Info files.  These settings apply to  all Info files,
   whether they are  opened manually or through  the Info interface.  This file
   also contains  definitions for any commands  and mappings that are exclusive
   to Info files.

From now  on I  will be  making a  distinction between  Info *files*  which are
actual files  in the  file system,  and Info  *documents*  which  is what  Info
displays. An Info document can be an Info file, but it can also be assembled on
the fly from multiple files. Standalone Info makes no distinction between these
two.


Data structures
===============

The following data structures are used throughout the plugin:

`b:info`
   A dictionary  that contains  all the  information  about  the Info-node.  In
   particular the file,  name of the node,  and parent, next and previous node.
   In this regard it mirrors the node header.

   The dictionary can contain other information as well. The `Menu` entry lists
   all menu items that occur in the node. A menu item is stored as a reference.

   This variable should be used for  any Information about the node itself,  it
   offers a single uniform location for information used by the plugin.
   
References
   A reference  is a dictionary  holding all  the information  needed to find a
   particular node.  It may carry even more information if necessary, such as a
   line number to jump to.

   A reference should contain a file and node, but if those are not given `dir`
   and `Top` are assumed implicitly. References can be encoded as URIs and URIs
   can be decoded into references.

URI
   A URI is  a string with  the syntax  `info://file/node#line`.  See below for
   more information.  A URI can be encoded from  a reference and decoded into a
   reference.


The Info URI
============

We can describe a position inside the node system using a URI scheme:

.. code-block::

   info://file/node?line=n&column=m

The name  of the scheme is  `info`, the host is  the name of the  document, the
path is the node and the query can  contain a line- or column number. To access
the  `dir` document  omit the  host and  path,  to access  the root  node of  a
document omit the path. Here are some examples:

.. code-block::

   # Directory node
   info://

   # Manual for the Bourne Again Shell
   info://bash/

   # Section 1.1 of the Bourne Again Shell manual
   info://bash/what%20is%20bash%3f/

   # Line 3 of section 1.1 of the Bourne Again Shell manual
   info://bash/what%20is%20bash%3f/?line=3&column=7

We have to  percent-encode the  spaces (`%20`)  and the question  mark (`%3f`).
Slashes at the end of  the host or path are  optional if there is no successive
element.

URIs can be decoded to  references and references can be encoded as URIs,  they
are dual to  each other.  A reference  is a dictionary  of `file` ,  `node` and
`line` keys.  The decoding function  is responsible for  filling missing values
with the proper defaults (file `dir`, node `Top` and line `1`).


Reading an Info document
========================

We will  not be  assembling the  Info  document  out of  the individual  files.
Instead we read the  output from the `info`  command-line tool into the buffer.
There are two ways to open an Info document: by passing its name to the `:Info`
command and by editing a buffer with a URI that begins with `info://<topic>`.

When using the `:Info` a window is chosen based on some rules and a buffer with
a generated URI is edited.  From that point on the  flow of control is the same
as opening an Info document by URI. Here is a simplified code draft:

.. code-block:: vim

   function! info#info(topic)
       let uri = 'info://' . a.topic
       " This line files an autocommand
       execute 'split' l:uri
   endfunction

   function! info#read_doc(uri)
      let topic = substitute(matchstr(a:uri, 'info://\zs.*'), '\v\/$', '', '')
      call read_topic(l:topic)
   endfunction

Once we have a new  buffer and a topic it's just  a matter of setting the extra
options for  documents  and  reading in  the output  of `info`.  Make  sure  to
write-lock the buffer only after the document has been written.


Processing menus
================

Menus are straight-forward, but ugly to work  with. Internally a menu is a list
of entries in the same order they appear in the document. If a node has no menu
then no menu variable will exist in that node.

Each entry is a reference with  keys `name` (human-readable title),  `file` and
`node`.  Menu entries  can be  written in  two forms  as discussed above,  so a
decoding function has to recognise and handle both.

Refer to the source code for details,  parsing a menu is very straight-forward.
The only difficulty is that  we don't have any way  of knowing when the menu is
terminated, so we have to read the entire rest of the node.

The menu is used  for jumping to entries,  finding entries and for building the
location list.


Testing
#######

See `test/README.rst`_ for details.

.. _test/README.rst: test/README.rst
