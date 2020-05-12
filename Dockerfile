FROM jekyll/builder:3.8

# This version of the Alpine upstream Docker image has broken `curl`.
# See:
#     https://gist.github.com/so0k/3f0546be5f06431a55a0a90ac9c25da8
#
# For this reason, we upgrade the whole system.
RUN apk add -U curl && apk upgrade

COPY lib/                 /usr/local/lib
COPY action-entrypoint.sh /action-entrypoint.sh

ENTRYPOINT ["/action-entrypoint.sh"]
