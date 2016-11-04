.. default-role:: code

####################################
 Working on the info plugin for Vim
####################################

This document is intended for programmers who want to work on info.vim, add new
features,  fix bugs or just  learn how it works and why  certain decisions have
been made. I will assume the reader to be familiar with how Vim plugins work in
general.  All files  follow the  usual directory  hierarchy,  so you  will find
everything where you expect it.


Overview of the plugin design
#############################

The basic idea of info.vim is to make  Vim a first-class reader for text in the
Info format, just like the standalone info and Emacs's info mode. This includes
and is not limited  to finding info  files in the same  directories as info and
Emacs do,  skipping to the  beginning o f the first node,  hiding or  replacing
markup information, and offering easy navigation.

Non-goals are the generation or organisation of info files.  Editing info files
is no priority,  but should not be inhibited.  Users are themselves responsible
for compiling info files and deciding where to install them.

The most important aspect is that we are not trying to write another info.  Vim
is a text editor,  not an  operating system,  our goal is to make  browsing and
reading info files more pleasant, not to embed an entire program into Vim.  Use
Vim's own features and add as little as possible of your own.  If something can
be achieved with less than five  lines of VimScript then chances are that it is
best left to the user to set.


The info file format
====================

The following is an informal format description suitable for our needs. An info
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

   We don't acutally need the following  features if we read our info documents
   from an info compiler like the standalone `info`.

File header
   Some basic information about  the file itself before the first node, such as
   author or license.  Since the header  comes before  any node  it will  no be
   displayed by the reader

Indirect
   If an info file is split over multiple  files it is necessary to know how to
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
      info manual says the former is correct.

Emacs local variables
   These are used by Emacs similar to the `vim:...` modeline.

   .. code-block::

      ^_
      Local Variables:
      <variable>: <value>
      End:


The node structure
==================

And info document  (also called an  info file)  is made  of nodes.  These nodes
usually form a  tree-like hierarchy,  but this does  not necessarily have to be
the case.  The only truth  is that the  nodes form a  directed graph,  but this
graph may even contain cycles or unreachable nodes.

Each file has  one root node  that's named  `Top` by convention.  The root node
usually has  its first child  as its `Next` node,  but all  other nodes usually
have their next  sibling as their  `Next` and  their previous  sibling as their
`Previous`.

A node  can  have  a menu,  listing  other  nodes  there.  These  nodes  can be
considered to be "children" of that node, but don't take that term literally.
It only means that in the graph there is an edge from this node to the nodes
listed in the menu.

Putting everything together we can conclude that every node has an outgoing
edge to the nodes listed in the node header (`Next`, `Previous` and `Up`), as
well as to the nodes in the menu. If the nodes in the menu are not in a
different file we consider them to be children.

The standalone info program cannot access arbitrary nodes in a file, instead it
has to work through the node graph. For example, if we want to jump directly to
section 1.1 of the Bash manual we have to call info like this:

.. code-block:: sh

   # Will not work because node 'What is Bash' is unreachable from 'Top'
   info bash What\ is\ Bash

   # Will work because node 'Introduction' is reachable from 'Top'
   info bash Introduction What\ is\ Bash

We can see that info resolves our node path one node at a time to reach the
destination. This maps nicely to a URI as we will see later.

One special file is the `(dir)` file which contains a menu that maps to all the
other info files. It's a sort of root of roots if you will.


One format, two purposes
========================

There are  two purposes to  info files:  reading and writing  them as the plain
text files  they are,  or treating  them as  a complete work  of documentation.
Supporting the former only requires some light support for the syntax.

The latter however is more complex.  Such info buffers  will not be read from a
file,  instead they will be  generated by reading  the contents  of one or more
files,  assembling  them  into one  buffer,  building a  table of  contents and
replacing or  hiding markup elements.  This is  similar to  how a  plugin would
display manpages.

Both types of buffer have the same type,  but generated buffers need some extra
options set.


The meat and bones of info.vim
##############################

With the technicalities out of the way let's focus on the actual plugin. I will
skip syntax highlighting,  the syntax code  says it all.  The important code is
found in the following files:

`plugin/info.vim`
   Commands and auto-commands are defined here, nothing else.

`autoload/info.vim`
   Most of the code that does the actual heavy lifting.

`after/ftplugin/info/folding.vim`
   Folding.

`ftplugin/info.vim`
   File-type settings for info files.  These settings apply to  all info files,
   whether they are opened manually or through the info interface. Files opened
   through the  info  interface  have  additional  options which  as  set  upon
   opening.

   This file also contains  definitions for any commands  and mappings that are
   exclusive to info files.

From now  on I  will be  making a  distinction between  info *files*  which are
actual files  in the  file system,  and info  *documents*  which  is what  info
displays. An info document can be an info file, but it can also be assembled on
the fly from multiple files.


The info URI
============

We can describe a position inside the node system using a URI scheme:

.. code-block::

   info://document/node-1/node-2/node-3#menu

The name of  the scheme is `info`,  the host is  the name of the document,  the
path is the sequence of nodes to traverse (excluding the root) and the fragment
can be a  particular part of the node,  such as `menu` for the node's menu.  To
access the `(dir)` document omit the host and path,  to access the root node of
a document omit the path. Here are some examples:

.. code-block::

   # Directory node
   info://

   # Manual for the Bourne Again Shell
   info://bash/

   # Section 1.1 of the Bourne Again Shell manual
   info://bash/introduction/what%20is%20bash%3f/

We have to percent-encode the spaces (`%20`) and the question mark (`%3f`).


Reading an info document
========================

We will  not be  assembling the  info  document  out of  the individual  files.
Instead we read the  output from the `info`  command-line tool into the buffer.
There are two ways to open an info document: by passing its name to the `:Info`
command and by editing a buffer with a URI that begins with `info://<topic>`.

When using the `:Info` a window is chosen based on some rules and a buffer with
a generated URI is edited.  From that point on the  flow of control is the same
as opening an info document by URI. Here is a simplified code draft:

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


The table of contents
=====================

.. warning::

   Standalone info  does not  employ a  table of  contents,  but other  formats
   generate from Texinfo do so.  I don't whether we  should support a TOC if we
   don't load the entire file into the buffer.

Info documents  can get  very large,  so it is  important to  have some  way of
navigating them. We need to be able to do two things: find a node very quickly,
and maintain the  tree structure of the TOC.  The former can be achieved with a
dictionary `b:nodes` that gives us fast access to any node, while the latter is
achieved using  a list  (with nested  lists) `b:toc`.  This means  we have  two
variables at any point.


Data structures
---------------

The keys of `b:nodes` are the names of  the nodes and the values are themselves
dictionaries with the node's data. Here is an example:

.. code-block::

   'A quick tour': {
       'up': 'Introduction',
       'prev': '',
       'next': 'Getting started',
       'line': 251,
       'path': [0, 1, 0]
   }

Empty values  mean that is no such value.  The `path` key is special in that it
is not part of the node header text line,  we have to compute it ourselves.  We
will come back  to it later.  We also don't  use the `File`  value of the  node
because we don't need it.

The `b:toc` list is a list of dictionaries where every dictionary is an *entry*
in the TOC.  An entry is a dictionary  that lists its node  and its sub-tree in
the TOC. Example:

.. code-block::

   [{'node': 'Introduction', 'tree':
       [{'node': 'A quick tour', 'tree': []},
        {'node': 'Getting started', 'tree': []}]}]

Entries with an empty tree are leaf-entries.


Generating the TOC
------------------

To generate the TOC structes we have to loop over every node header that occurs
in the document in the order they occur. The first node is the root, from there
on use the following algorithm:

#) If the node has  no parent add its  entry to the outermost  level of the TOC
   (usually only applies to root node)
#) Else, find its parent TOC entry, it has the name of the `up` property
#) Append its entry to the parent entry's tree

To generate the  `b:nodes` dictionary add  the complete nodes  as you encounter
them to the dictionary.


The `path` property
-------------------

Mapping an entry  from `b:toc` to  a node in `b:nodes`  is easy: use the `node`
property as  the key  into `b:nodes`.  Mapping a  node to  a TOC  entry is more
involved.  We would be wasting too much time iterating over every branch of the
tree to find our node.  Instead we store a  sequence of indices into  the tree:
the `path`.

Suppose have a TOC that looks something like this:

.. code-block::

   R
   ├─O
   │ ├─O
   │ ├─O
   │ └─O
   ├─O
   └─O
     ├─O
     ├─O
     │ ├─X
     │ └─O
     └─O

Starting from  the root  `R` the  `path` to  node `X`  is `[0, 2, 1, 0]`.  When
rendering the `path` to  text we can omit the first  entry and add one to every
number to get a nice section numbering like `3.2.1.` for display.


Finding the current node
------------------------

Given the current line number, how do we find the node we are currently in?  We
will use a recursive  search algorithm on the TOC list (`b:toc`).  Given a flat
list of more than one  node we can pick a pivot node  and then compare the line
number  with  the `'line'` property  of the pivot node:  if the line  number is
lower than the node 's the line is in the lower half of the list,  otherwise in
the upper half (includes the pivot). If these is only one node in the list that
has to be the node  we are after,  under the condition  that the top-most  node
starts on the first line.

Here is the  algorithm in more detail.  The `list` is the current list of nodes
and `line` is the line number.

#) If `list` has only one element (`node`)

   #) If `node` is a leaf-node

      #) Return `node`

   #) Else

      #) If `line` is the line number of `node`

         #) Return `node`

      #) Else

         #) Recurse on the `tree` of `node`
#) Else

   #) Pick a `pivot` element from `list` (ideally in the middle of the list)

   #) If `line` is the line number of `pivot`

      #) return `pivot`

   #) Else if `line` is less than the line number of `pivot`

      #) Recurse on the first half of `list` (excluding `pivot`)

   #) Else (if `line` is greater than the line number of `pivot`)

      #) Recurse on the other half of `list` (including `pivot`)

This algorithm can fail if it is possible for a line to be before the node, but
the info compiler never produces such documents.
