FROM jekyll/builder

RUN apk add --no-cache --no-progress curl jq

COPY lib/                 /usr/local/lib
COPY action-entrypoint.sh /action-entrypoint.sh

ENTRYPOINT ["/action-entrypoint.sh"]
