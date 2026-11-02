FROM jenkins/ssh-agent

# php-sqlite3 and sqlite3 are needed by the tests of the PHP project (SQLite database)
RUN apt-get update && \
    apt-get install -y php-cli php-sqlite3 sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# the project config expects the database here; the build runs as jenkins, not root
RUN mkdir -p /var/www/db && chown jenkins:jenkins /var/www/db
