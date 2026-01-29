FROM alpine:3.20

RUN apk add --no-cache git inotify-tools nodejs npm

WORKDIR /knowledge

COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN npm install -g @modelcontextprotocol/server-filesystem

ENTRYPOINT ["/entrypoint.sh"]
