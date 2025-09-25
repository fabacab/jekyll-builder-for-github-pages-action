FROM jekyll/builder:4

RUN apk add --no-cache --no-progress curl

COPY lib/                 /usr/local/lib
COPY action-entrypoint.sh /action-entrypoint.sh

ENTRYPOINT ["/action-entrypoint.sh"]
