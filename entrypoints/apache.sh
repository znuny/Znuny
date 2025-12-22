#!/bin/bash
# You can do some boot checks, like initial setup steps here.
echo Listening on port $external_port
exec "$@"