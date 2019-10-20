#! /bin/sh
#
# kong.sh
#
# Distributed under terms of the GPL license.
#

resty -I /usr/lib64/lua/5.1 /kong/bin/kong $*

# test  h