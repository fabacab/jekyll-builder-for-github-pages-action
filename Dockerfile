FROM jekyll/builder@sha256:a8345b1d5316347dccd73ed4e96cb08e29bd8b2634bb727fb4d9311fe1e3ec89

RUN apk add --no-cache --no-progress curl

COPY lib/                 /usr/local/lib
COPY action-entrypoint.sh /action-entrypoint.sh

ENTRYPOINT ["/action-entrypoint.sh"]
