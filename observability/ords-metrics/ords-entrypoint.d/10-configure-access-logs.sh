#!/bin/sh
set -eu

mkdir -p /var/log/ords/access /var/log/ords/service

ords --config /etc/ords/config config set --global standalone.access.log /var/log/ords/access
ords --config /etc/ords/config config set --global standalone.access.log.retainDays 10
ords --config /etc/ords/config config set --global instance.api.enabled true
