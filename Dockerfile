FROM python:3.9.18-alpine3.18 as builder

WORKDIR /app

COPY requirements.txt /app/
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . ./
RUN mkdocs build --strict --site-dir site

FROM nginx:1.25.4-alpine3.18

RUN adduser -D docs
RUN chown -R docs \
    /etc/nginx/conf.d \
    /usr/share/nginx/html/ \
    /var/cache/nginx/ \
    /var/run/
USER docs

COPY --chown=docs --from=builder /app/site /usr/share/nginx/html
COPY --chown=docs ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

ENTRYPOINT [ "/usr/sbin/nginx", "-g", "daemon off;" ]
