execute immediate $$
begin
  begin transaction;
  DELETE FROM &table_name WHERE id = '&id';
  COPY INTO &table_name (id, ym, h_txt, t_value, h_order)
    FROM (SELECT $1:id, $1:ym, $1:h_txt, $1:t_value, $1:h_order FROM @my_s3_stage)
    PATTERN='d[0-9]+/data.*'
    FILE_FORMAT = (TYPE=JSON);
  commit;
exception
  when other then
    rollback;
    raise; -- Raise the same exception that you are handling.  
end;
$$
;