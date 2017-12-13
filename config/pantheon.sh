#!/bin/bash

#
# FROM PANTHEON:
#   Pantheon containers spin down after ~1 hour of idle time. Live environments 
#   on a paid plan will spin down after 12 hours of idle time. Upon receiving a 
#   web request, the environments are spun up, usually within 30 seconds. 
#   (source: https://pantheon.io/docs/application-containers/)
#

# Time while pantheon keeps their dev server's live. After this time
# they will spin them down until they are accessed again through it's URL
PANTHEON_KEEP_ALIVE=3000 # seconds = 50 minutes.
