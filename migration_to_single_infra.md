# Get RDS endpoint from terraform output or AWS console
RDS_HOST="nextjs-pdf-extractor-db.c9ss68iashbd.us-west-1.rds.amazonaws.com"
DB_NAME="mydb"
DB_USER="postgres"
DB_PASSWORD="medbnk000"

# Export database to local file
pg_dump -h $RDS_HOST \
  -U $DB_USER \
  -d $DB_NAME \
  -F c \
  -f certification-db-backup-$(date +%Y%m%d-%H%M%S).dump

# Or plain SQL format
pg_dump -h $RDS_HOST \
  -U $DB_USER \
  -d $DB_NAME \
  > certification-db-backup-$(date +%Y%m%d-%H%M%S).sql
