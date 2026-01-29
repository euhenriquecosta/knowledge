FROM alpine:3.20

RUN apk add --no-cache git inotify-tools

WORKDIR /knowledge

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
