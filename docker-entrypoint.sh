#!/bin/sh
set -e

# Shorthand: `docker run <image> -token xxx` == `miaospeed server -token xxx`.
if [ "${1#-}" != "$1" ]; then
    set -- server "$@"
fi

if [ "$1" = "server" ]; then
    # Env-driven defaults; explicit flags always win.
    if [ -n "$TOKEN" ]; then
        case " $* " in
            *" -token "*) ;;
            *) set -- "$@" -token "$TOKEN" ;;
        esac
    fi
    if [ -n "$BIND" ]; then
        case " $* " in
            *" -bind "*) ;;
            *) set -- "$@" -bind "$BIND" ;;
        esac
    fi
    # Default bind address when neither flag nor env is provided.
    case " $* " in
        *" -bind "*) ;;
        *) set -- "$@" -bind 0.0.0.0:8080 ;;
    esac
fi

# Route miaospeed subcommands (server/script/misc/...) through the binary;
# anything that is a real program (e.g. `sh`) is executed as-is.
if ! command -v "$1" >/dev/null 2>&1; then
    set -- miaospeed "$@"
fi

exec "$@"
