ARG ELIXIR_IMAGE=docker.io/elixir:latest
FROM ${ELIXIR_IMAGE}

ARG APP_DIR
ARG PHOENIX_VERSION
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y inotify-tools && \
    mix local.hex --force && \
    mix archive.install --force hex phx_new $(echo ${PHOENIX_VERSION} | sed 's/^v//') && \
    mix local.rebar --force

## NodeJS is not needed for Phoenix >=1.6, leave NODEJS_VERSION blank to skip install:
ARG NODEJS_VERSION
RUN test -z "$NODEJS_VERSION" || curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION} | bash && \
    test -z "$NODEJS_VERSION" || apt-get install -y nodejs

WORKDIR /root/src
ADD ${APP_DIR}/ /root/src

EXPOSE 4000
CMD ["mix", "phx.server"]
