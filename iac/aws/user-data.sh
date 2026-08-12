#!/bin/bash
# Amazon Linux 2023. No usa app/user-data.sh: ese script instala MariaDB en la VM (ADR 008).
set -euo pipefail
dnf install -y httpd php
mkdir -p /var/www/html
echo ok > /var/www/html/health
echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php
systemctl enable --now httpd
