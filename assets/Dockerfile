FROM swift:5.9.2-jammy

RUN \
  apt update && \
  apt upgrade -y && \
  apt install -y postgresql postgresql-client postgresql-contrib libpq-dev sudo

RUN \
  pg_ctlcluster 14 main start && \
  sudo -u postgres psql -c "CREATE ROLE swiftpq_test WITH LOGIN PASSWORD 'swiftpq_test';" && \
  sudo -u postgres psql -c "CREATE DATABASE swiftpq_test WITH OWNER swiftpq_test;" && \
  sed -i -E 's/^local([[:space:]]+)all([[:space:]]+)all([[:space:]]+)peer/local\1all\2all\3scram-sha-256/' /etc/postgresql/14/main/pg_hba.conf

ENTRYPOINT \
  pg_ctlcluster 14 main start && \
  pg_lsclusters && \
  /bin/bash