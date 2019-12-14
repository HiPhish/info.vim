.. default-role:: code

##################
 Testing Info.vim
##################

We use Vader_ for testing. All tests are stored in the `vader/` directory, one
test file per Vim command. If you fixed a bug please add a test case for the
bug so it never comes back again. If you added a new feature add tests for it
so it remains functional.

Always use  the `info` file  type for `Given` and  `Expected` blocks and  add a
comment describing what the purpose of the  test is. Avoid terms like "test" or
"check" when possible, it's obvious we are doings tests when in a test suite.

Tests involving Standalone Info must use a  mock shell script in place of Info.
The mock takes the same arguments as Info,  so you have  to set the `g:infoprg`
variable to it using `Before` and `After`. Example:

.. code-block:: vader

   Before (Store old info binary so it can be restored):
     let g:old_infoprg = g:infoprg
     let g:infoprg = substitute(g:vader_file, '\v[^/]+\.vader$', '', '').'mock-info.sh'

   After (Restore the original info binary):
     let g:infoprg = g:old_infoprg

We have to restore the original value because the value persists even after the
test is done. Observe how we use the path of the test file, strip away the file
name and append the mock binary.

As for the files to test against, use the pre-rendered Info files included with
the test suite. The file name pattern is `<file>.<node>.info`.


Running tests
#############

Tests must be run from the root directory of the project. You can run a test
manually by executing the following line of code:

.. code-block:: vim

   Vader test/vader/name-of-test.vader

Substitute `name-of-test` for the name of the test file, or alternatively use
`*` to run all tests. You can also run all tests from the command-line using
the included makefile:

.. code-block:: sh

   make check

This might only work with Neovim_ though, I have not tested it with Vim_.


Directory overview
##################

- `bin` contains all mock binaries
- `vader` contains all Vader test scripts
- `info` contains all pre-rendered Info nodes; the mock Info scripts will just
  echo out the file contents


The mock Info script
####################

The shell script `mock-info.sh` serves as a replacement for the Info binary. It
accepts the same arguments, but instead of searching the user's system for Info
files and extracting nodes it only echoes back an existing text file.


The mock Info files
###################

These text files are what the output of Info would look like. They are served
by the mock Info script for testing. The naming scheme is `<file>.<node>.info`.
The name is important so the mock Info can locate the files.

When writing mock files only add as much information as necessary, but if an
existing file would be suitable for your additions prefer that over creating a
new file.


.. ----------------------------------------------------------------------------
.. _Vader: https://github.com/junegunn/vader.vim/
.. _Neovim: https://neovim.io/
.. _Vim: https://www.vim.org/
