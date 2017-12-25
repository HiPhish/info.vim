.. default-role:: code

How it works
############

This file does a lot of things as the same time because VimScript lacks a
proper module system, so here is my attempt at making sense of it. The
individual tasks are as follows:

Public interface
   Auto-commands, mappings and commands. Anything that is meant to be exposed
   to the user

Completion functions
   Tab-complete commands

Reading functions
   Getting content into the buffer and opening info files

Navigation functions
   Node navigation

Menu function
   Anything related to menus

Reference function
   Anything related to (cross-)references

URI-handing functions
   Anything URI-related

The fundamental idea of this plugin is to use standalone info as much as
possible and make use of the URI-reference duality. What this means is that
internally we pass reference objects around, but when it comes to actually
reading a buffer we send a URI to Vim. Vim tries to open the URI, which
triggers an auto-command, converting the URI back to a reference and allowing
the plugin to send the required information to info.

The scheme is:

1) Call `:Info`, this generates a URI and find a window
2) Edit the URI
3) This fires and auto-command, converting the URI back to a reference
4) The reference is used for everything else from now

The first step is optional, it does not matter how we get Vim to `:edit` the
URI. For instance, when following a reference or going to the next node we
convert the reference to a URI and `:edit` it in the current window.


URI encoding and decoding
=========================

A URI may contain percent characters (percent encoding), which in an ex-command
are interpreted as "the current file". For this reason they must be escaped. To
cut down the redundancy use the `s:executeURI` function.


Calling an external tool
========================

External tools are called from the shell, so the command strings needs to be
properly escaped. This does not just mean escaping spaces, but also adjusting
redirection for different shells. Use the `s:encodeCommand` function.
