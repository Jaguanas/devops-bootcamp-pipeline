FROM php:8.3-apache

COPY app/ /var/www/html/

EXPOSE 80