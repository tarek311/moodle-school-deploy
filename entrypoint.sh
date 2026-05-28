#!/bin/bash
set -e

# Generate config.php from environment variables on every startup
php -r "
\$c  = '<?php' . PHP_EOL;
\$c .= 'unset(\$CFG); global \$CFG; \$CFG = new stdClass();' . PHP_EOL;
\$c .= '\$CFG->dbtype    = \"pgsql\";' . PHP_EOL;
\$c .= '\$CFG->dblibrary = \"native\";' . PHP_EOL;
\$c .= '\$CFG->dbhost    = \"' . getenv('PGHOST')     . '\";' . PHP_EOL;
\$c .= '\$CFG->dbname    = \"' . getenv('PGDATABASE') . '\";' . PHP_EOL;
\$c .= '\$CFG->dbuser    = \"' . getenv('PGUSER')     . '\";' . PHP_EOL;
\$c .= '\$CFG->dbpass    = \"' . getenv('PGPASSWORD') . '\";' . PHP_EOL;
\$c .= '\$CFG->prefix    = \"mdl_\";' . PHP_EOL;
\$c .= '\$CFG->wwwroot   = \"https://' . getenv('MOODLE_HOST') . '\";' . PHP_EOL;
\$c .= '\$CFG->dataroot  = \"/var/moodledata\";' . PHP_EOL;
\$c .= '\$CFG->admin     = \"admin\";' . PHP_EOL;
\$c .= '\$CFG->directorypermissions = 0777;' . PHP_EOL;
\$c .= '\$CFG->sslproxy  = true;' . PHP_EOL;
\$c .= 'require_once(__DIR__ . \"/lib/setup.php\");' . PHP_EOL;
file_put_contents('/var/www/moodle/config.php', \$c);
echo 'config.php written' . PHP_EOL;
"

chown www-data:www-data /var/www/moodle/config.php

# Use flag file in persisted moodledata to detect first boot
INSTALLED_FLAG="/var/moodledata/.db_installed"
if [ ! -f "$INSTALLED_FLAG" ]; then
    echo "First boot: running Moodle database installer..."
    php /var/www/moodle/admin/cli/install_database.php \
        --agree-license \
        --fullname="School System" \
        --shortname="school" \
        --adminuser="${MOODLE_ADMIN_USER:-admin}" \
        --adminpass="${MOODLE_ADMIN_PASS:-Admin@2024!}" \
        --adminemail="${MOODLE_ADMIN_EMAIL:-admin@school.local}" \
        --lang=ar \
    && touch "$INSTALLED_FLAG" \
    && echo "Moodle installation complete."
else
    echo "Moodle already installed, skipping installer."
fi

exec /usr/sbin/apache2 -D FOREGROUND
