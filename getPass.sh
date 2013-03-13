#!/bin/sh

# Set this script as $SSH_ASKPASS accociated with $DISPLAY, and this script will echo back $PASS as the SSH password.
# SSH_ASKPASS
# "If ssh needs a passphrase, it will read the passphrase from the current terminal if it was run from a terminal. 
# If ssh does not have a terminal associated with it but DISPLAY and SSH_ASKPASS are set,
# it will execute the program specified by SSH_ASKPASS and open an X11 window to read the passphrase. 
# This is particularly useful when calling ssh from a .Xsession or related script. 
# (Note that on some machines it may be necessary to redirect the input from /dev/null to make this work.)"

echo $PASS;