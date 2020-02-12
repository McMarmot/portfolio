

CREATE DEFINER=`credo_lianna`@`%` PROCEDURE `update yesterday_mids`()
BEGIN

INSERT INTO procedure_log
SELECT 'update yesterday_mids ' as procedure_name, CURRENT_TIMESTAMP() as started_at, null;

SET @start_date = curdate();

DROP TABLE IF EXISTS yesterdaymids;
CREATE TABLE yesterdaymids AS

SELECT m.id, m.finished_at, m.notes,
(SELECT t.name FROM ak_credo.core_tag t JOIN ak_credo.core_mailing_tags mt ON t.id = mt.tag_id WHERE mt.mailing_id = m.id AND t.name IN ('petition', 'call', 'welcome_email', 'event')) AS type,
(SELECT t.name FROM ak_credo.core_tag t JOIN ak_credo.core_mailing_tags mt ON t.id = mt.tag_id WHERE mt.mailing_id = m.id  AND t.name IN ('segment a tests', 'segment b', 'segment c', 'subject line test')) AS universe,
m.progress, '0' AS counter
FROM ak_credo.core_mailing m
WHERE m.finished_at >@start_date - INTERVAL 1 DAY
AND m.finished_at < @start_date
AND m.progress IS NOT NULL
AND m.progress <>0
AND m.notes NOT LIKE ('%DELIVERY%');

UPDATE yesterdaymids
SET type ='welcome'
WHERE notes LIKE ('%Welcome%')
;


UPDATE yesterdaymids
SET type ='reactivation'
WHERE notes LIKE ('#%')
;

UPDATE yesterdaymids
SET type ='newsletter'
WHERE notes LIKE ('%newsletter%')
;


UPDATE yesterdaymids
SET universe ='new'
WHERE notes LIKE ('%Welcome%')
;



UPDATE yesterdaymids
SET universe ='reactivation'
WHERE type = 'reactivation'
;

UPDATE yesterdaymids
SET universe ='newsletter'
WHERE notes LIKE ('%newsletter%');

UPDATE yesterdaymids
SET universe ='deep actives'
WHERE type LIKE ('event');

UPDATE yesterdaymids
SET universe ='callers'
WHERE type LIKE ('call');


UPDATE yesterdaymids
SET type ='clicker kicker'
WHERE notes LIKE ('%Clicker%');

UPDATE yesterdaymids
SET universe ='clicker kicker'
WHERE type = 'clicker kicker';

UPDATE yesterdaymids
SET type ='2020 survey',
universe = 'Seg C partial'
WHERE notes LIKE ('%2020%');

INSERT INTO d_master
SELECT id, finished_at, notes, type, universe, progress, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL FROM yesterdaymids;



DROP TEMPORARY TABLE IF EXISTS delivery_opens;

CREATE TEMPORARY TABLE delivery_opens
SELECT y.id, COUNT(DISTINCT o.user_id) AS opens
FROM yesterdaymids y
JOIN ak_credo.core_open o ON o.mailing_id = y.id
GROUP BY 1;


UPDATE d_master
JOIN delivery_opens do ON d_master.id = do.id
SET d_master.opens = do.opens;

DROP TEMPORARY TABLE IF EXISTS delivery_12hropens;

CREATE TEMPORARY TABLE delivery_12hropens
SELECT y.id, COUNT(DISTINCT o.user_id) AS 12_hr_opens
FROM yesterdaymids y
JOIN d_master d ON d.id = y.id
JOIN ak_credo.core_open o ON (o.mailing_id = y.id
AND o.created_at < d.finished_at + INTERVAL 12 HOUR)
GROUP BY 1;


UPDATE d_master
JOIN delivery_12hropens do ON d_master.id = do.id
SET d_master.12_hr_opens = do.12_hr_opens;



DROP TEMPORARY TABLE IF EXISTS delivery_clicks;

CREATE TEMPORARY TABLE delivery_clicks
SELECT y.id, COUNT(DISTINCT c.user_id) AS clicks
FROM yesterdaymids y
JOIN ak_credo.core_click c ON c.mailing_id = y.id
GROUP BY 1;


UPDATE d_master
JOIN delivery_clicks dc ON d_master.id = dc.id
SET d_master.clicks = dc.clicks;


DROP TEMPORARY TABLE IF EXISTS delivery_actions;

CREATE TEMPORARY TABLE delivery_actions
SELECT y.id, COUNT(DISTINCT a.user_id) AS actions
FROM yesterdaymids y
JOIN ak_credo.core_action a ON a.mailing_id = y.id
GROUP BY 1;


UPDATE d_master
JOIN delivery_actions da ON d_master.id = da.id
SET d_master.actions = da.actions;

UPDATE procedure_log
SET finished_at = CURRENT_TIMESTAMP()
WHERE finished_at IS NULL
AND procedure_name = 'update yesterday_mids';

DROP TABLE IF EXISTS yesterdaymids_counter;
CREATE TABLE yesterdaymids_counter AS
SELECT id, '0' AS counter FROM yesterdaymids ;

END
