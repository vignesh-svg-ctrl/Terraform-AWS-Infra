#!/bin/bash
set -euxo pipefail

dnf install -y httpd

systemctl enable httpd
systemctl start httpd

cat <<EOF > /var/www/html/index.html
<html>
  <head>
    <title>Terraform 2-Tier Architecture</title>
  </head>
  <body>
    <h1>Hello from Private EC2</h1>
    <p>Served via ALB + NAT Gateway</p>
  </body>
</html>
EOF
