.. default-role:: code

##########################
 Contributing to info.vim
##########################

There are a number of ways you can help with this project:

Report bugs
   You know  the drill: what  is the problem, how  do you reproduce  it? Please
   provide a  minimum (non-)working example to  tell me what Info  document you
   are having trouble and what line.

Submit merge requests
   Read  the `HACKING`  file first  to understand  the code,  then submit  your
   improvements. Unless  it's a pure  fix you should  open an issue  to discuss
   your idea so you don't end up wasting your time for nothing.

Please note  that the main  repository is on GitLab,  not GitHub, so  only send
merge requests  there. Issues on  GitHub are  OK if you  don't want to  sign up
there, but I  would prefer GitLab for  that as well just to  have everything in
one place.


Style guide
###########

There is not much  in the way of style, but there are  some basic guidelines to
follow:

- Capitalise the name Info when you mean the program and Info.vim when you mean
  this plugin. User lower-case `info` when referring to the literal name of the
  binary and mark it  up as a `code literal`. If you  find instances where this
  isn't the case feel free to fix it.

- Use  tabs for indentation in  VimScript files, spaces everywhere  else. Three
  spaces in reStructuredText, two spaces in Vader.

- Justify text in reStructuredText files.  I use `par -w79j`  as my `formatprg`
  option.  Do not put extra spaces in inline `code literals` and do not justify
  code blocks.

For everything else use your best judgment and imitate the existing style.


Testing
#######

See `test/README.rst`_ for details.

.. _test/README.rst: test/README.rst
