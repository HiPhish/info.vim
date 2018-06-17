.. default-role:: code

##################
 Testing Info.vim
##################

We use Vader_  for testing. All tests  are stored under `test/`,  one test file
per command. If you fixed a bug please add  a test case for the bug so it never
comes back  again. If you added  a new feature add  tests for it so  it remains
functional.

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

.. _Vader: https://github.com/junegunn/vader.vim/


The mock Info script
####################

The shell script `mock-info.sh` serves as a replacement for the Info binary. It
accepts the same arguments, but instead of searching the user's system for Info
files and extracting nodes it only echoes back an existing text file.

Those files are found under `test/mock/`.
