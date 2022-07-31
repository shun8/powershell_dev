CREATE STORAGE INTEGRATION test_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '<iamのarn>'
  STORAGE_ALLOWED_LOCATIONS = ('<s3パス>')
;
DESC INTEGRATION test_integration;

create stage my_s3_stage
  storage_integration = test_integration
  url = '<s3パス>';

COPY INTO h_0 (id, ym, h_txt, t_value, h_order)
  FROM (SELECT $1:id, $1:ym, $1:h_txt, $1:t_value, $1:h_order FROM @my_s3_stage)
  PATTERN='d[0-9]+/data.*'
  FILE_FORMAT = (TYPE=JSON);

snowsql -a <account>.ap-northeast-1.aws -d test -u <user> -f ..\sql\transaction_test.sql -D table_name=h_0 -D id=00005 -o variable_substitution=true -s public