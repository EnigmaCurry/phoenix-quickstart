ARG ELIXIR_IMAGE=docker.io/elixir:latest
FROM ${ELIXIR_IMAGE}

ARG APP_DIR
ARG PHOENIX_VERSION
ARG NODEJS_VERSION
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential inotify-tools && \
    mix local.hex --force && \
    mix archive.install --force hex phx_new $(echo ${PHOENIX_VERSION} | sed 's/^v//') && \
    mix local.rebar --force && \
    curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION} | bash && \
    apt-get install -y nodejs

WORKDIR /root/src
ADD ${APP_DIR}/ /root/src

EXPOSE 4000
CMD ["mix", "phx.server"]
