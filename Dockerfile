FROM openresty/openresty:jessie

MAINTAINER Xiejiangzhi <jzxie@wind.com.cn>

COPY ./nginx /openresty
COPY ./resty /openresty/lualib/resty

RUN rm -rf /openresty/*_temp

EXPOSE 80

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

