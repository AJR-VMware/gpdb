--
-- Test ALTER TABLE REPACK BY COLUMNS (...) 
--
CREATE DATABASE at_repack;
\c at_repack
--------------------------------------------------

--------------------------------------------------
-- test basic functionality, will shrink disk size of misloaded tables
-- AORO
CREATE TABLE repack_aoro(i int, j int, k text) WITH (appendoptimized=true, compresstype=zstd, compresslevel=3) distributed by (i);
-- AJR TODO -- figure out how to bloat this table
INSERT INTO repack_aoro SELECT j, j%3, 'tryme' FROM generate_series(1, 100000)j;

select pg_size_pretty(pg_relation_size('repack_aoro', false, true));
ALTER TABLE repack_aoro REPACK BY COLUMNS (i);
select pg_size_pretty(pg_relation_size('repack_aoro', false, true));

-- AOCO
CREATE TABLE repack_aoco(i int, j int, k text) WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=3) distributed by (i);
-- AJR TODO -- figure out how to bloat this table
INSERT INTO repack_aoco SELECT j, j%3, 'tryme' FROM generate_series(1, 100000)j;
select pg_size_pretty(pg_relation_size('repack_aoco', false, true));
ALTER TABLE repack_aoco REPACK BY COLUMNS (i);
select pg_size_pretty(pg_relation_size('repack_aoco', false, true));
--------------------------------------------------

--------------------------------------------------
-- test that expected warnings/errors are printed
CREATE TABLE err_heap(i int, j int, k text) distributed by (i);
ALTER TABLE err_heap REPACK BY COLUMNS (i);

CREATE TABLE warn_nocompr_tbl(i int, j int, k text) WITH (appendoptimized=true, compresstype=none) distributed by (i);
ALTER TABLE warn_nocompr_tbl REPACK BY COLUMNS (i);

CREATE TABLE warn_nocompr_cols(i int, j int, k text) WITH (appendoptimized=true, orientation=column) distributed by (i);
ALTER TABLE warn_nocompr_cols ADD COLUMN l int default 0 encoding (compresstype=none);
ALTER TABLE warn_nocompr_cols REPACK BY COLUMNS (i,l);
--------------------------------------------------

--------------------------------------------------
-- test that addressing by column number works
CREATE TABLE repack_aoco_colnum(i int, j int, k text) WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=3) distributed by (i);
ALTER TABLE repack_aoco_colnum REPACK BY COLUMNS (1, 2);
--------------------------------------------------

--------------------------------------------------
-- clean up database
\c regression
DROP DATABASE at_repack;
--------------------------------------------------

