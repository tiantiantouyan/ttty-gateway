FROM openresty/openresty:alpine

MAINTAINER Xiejiangzhi <jzxie@wind.com.cn>

COPY ./nginx /openresty

RUN rm -rf /openresty/*_temp
RUN rm -rf /openresty/logs/*

EXPOSE 80

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;", "-p", "/openresty"]

