FROM nginx:1.29-alpine

RUN addgroup -S app \
    && adduser -S -G app app

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY index.html /usr/share/nginx/html/index.html

RUN sed -i \
      's/user  nginx;/user  app;/' \
      /etc/nginx/nginx.conf \
    && mkdir -p \
      /var/cache/nginx \
      /var/run \
    && chown -R app:app \
      /var/cache/nginx \
      /var/run \
      /usr/share/nginx/html \
      /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown app:app /var/run/nginx.pid

USER app

EXPOSE 80
