FROM golang:alpine as gobuild

ARG TAG

RUN apk update && \
    apk add ca-certificates gcc git make musl-dev && \
    git clone --depth 1 --branch $TAG https://github.com/mattermost/focalboard && \
    cd focalboard && \
    make server-linux

FROM node:alpine as nodebuild

COPY --from=gobuild /go/focalboard /focalboard
RUN cd /focalboard/webapp && \
    npm install && npm run pack

FROM alpine:latest

ARG PUID=2000
ARG PGID=2000

EXPOSE 8000/tcp

RUN addgroup -g ${PGID} focalboard && \
    adduser -H -D -u ${PUID} -G focalboard focalboard

WORKDIR /opt/focalboard

COPY --from=nodebuild /focalboard/bin/linux/focalboard-server bin/
COPY --from=nodebuild /focalboard/webapp/pack pack/
COPY --from=nodebuild /focalboard/LICENSE.txt LICENSE.txt
COPY --from=nodebuild /focalboard/server-config.json config.json

RUN chown -R ${PUID}:${PGID} /opt/focalboard

USER focalboard

CMD ["/opt/focalboard/bin/focalboard-server"]
