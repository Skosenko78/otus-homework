FROM alpine:3.14
RUN apk update && apk upgrade
RUN apk add nginx
COPY index.html /var/www
COPY default.conf /etc/nginx/http.d/default.conf
EXPOSE 80/tcp
ENTRYPOINT ["nginx", "-g", "daemon off;"]