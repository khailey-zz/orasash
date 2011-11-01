
SET HEAD OFF
SET VER OFF
set feedback off

spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') != upper('SYS');
spool off
@exit.sql

prompt "------------------------------------------------------------------------------------"
prompt  Creating repository owner and job kill function using SYS user                     
prompt "------------------------------------------------------------------------------------"

spool sys_objects.log
@repo_user.sql
@repo_sys_procedure.sql
spool off

WHENEVER SQLERROR CONTINUE NONE 

connect &SASH_USER/&SASH_PASS
set term off
spool exit.sql
select 'exit' from dual where SYS_CONTEXT ('USERENV', 'SESSION_USER') != upper('&SASH_USER');
spool off
@exit.sql

set term on
prompt "------------------------------------------------------------------------------------"
prompt  Installing SASH objects into &SASH_USER schema                                     
prompt "------------------------------------------------------------------------------------"
set term off

@repo_schema.sql
@sash_repo.sql
@sash_pkg.sql
@sash_xplan.sql
set term on

prompt "------------------------------------------------------------------------------------"
prompt  Instalation completed. Starting SASH configuration process                         
prompt "------------------------------------------------------------------------------------"


accept DBNAME prompt "Enter database name " 

accept INST_NUM default 1 prompt "Enter number of instances [default 1]"

SET TERMOUT OFF

spool instance.sql
select 'accept HOST' || rownum || ' prompt "Enter hostname for instance number ' || rownum || ' "' from all_source where rownum <= &INST_NUM;
spool off

SET TERMOUT ON

@instance.sql

accept PORT default 1521 prompt "Enter listener port number [default 1521] "
accept SASHPASS prompt "Enter SASH password on target database "

set term off
spool setup.sql
select 'exec sash_repo.add_db(''&' || 'HOST' || rownum || ''', ' || &PORT || ', ''&SASHPASS'', ''&DBNAME'', ''&DBNAME' || rownum || ''',' || rownum || ', ''11.2.0.2'', 8);' from all_source where rownum <= &INST_NUM;
select 'exec sash_pkg.configure_db(''&DBNAME' || 1 || ''');' from dual;
select 'exec sash_pkg.set_dbid(''&DBNAME' || 1 || ''');' from dual;
select 'exec sash_repo.setup_jobs' from dual;
select 'exec sash_repo.start_collecting_jobs' from dual;
select 'exec sash_repo.purge' from dual;
spool off
set term on

@setup.sql

exit 
