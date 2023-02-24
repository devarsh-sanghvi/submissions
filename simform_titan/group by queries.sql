---------------------------> Query 1: Department Name, Number Of Total Audits, Minimum Score, Max Score, Avg Score, Madian Score <---------------------------
SELECT 
	ld.display_text AS department_name,
	COUNT(*) AS total_audits,
	MAX(score_by_auditor) AS max_score_by_auditor,
	MIN(score_by_auditor) AS min_score_by_auditor,
	ROUND(AVG(score_by_auditor), 2) AS avg_score_by_auditor,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY score_by_auditor) AS median_score_by_auditor
FROM audit_schedules aus
LEFT JOIN lookups ld
	ON aus.department_id = ld.lookup_id
GROUP BY department_name;



---------------------------> Query 2: Department Name, Month Name, Year, Total Audit Count <---------------------------
SELECT 
	ld.display_text AS department_name,
	TO_CHAR(original_schedule_date_time, 'Month') AS audit_month,
	EXTRACT(YEAR FROM original_schedule_date_time) AS audit_year,
	COUNT(*) AS total_audit
FROM audit_schedules aus
LEFT JOIN lookups ld
	ON aus.department_id = ld.lookup_id
GROUP BY department_name, audit_month, audit_year
ORDER BY department_name, TO_DATE(TO_CHAR(original_schedule_date_time, 'Month'),'Month'), audit_year;

---------------------------> Query 3: Department Name, Month Name, Year, Audit Type Name, Total Audit Count <---------------------------

-- Audit count by grouping: department , month , year, audit_type
select
	lu1.display_text department , 
	TO_CHAR(original_schedule_date_time,'Month') "month",
	extract(year from original_schedule_date_time) "year",
	lu2.display_text audit_type,
	count(*) total_audit_counts
from 
	public.audit_schedules aud_sch
left join
	public.lookups lu1
on
	aud_sch.department_id = lu1.lookup_id
left join
	public.lookups lu2
on
	aud_sch.audit_type_id = lu2.lookup_id
group by
	department , month , year, audit_type
order by
	department, to_date(to_char(original_schedule_date_time, 'Month'),'Month')
	


---------------------------> Query 4: Auditor Name, Audit Status Name, Total Audit Count <---------------------------

-- Audit Count grouped by: auditor_name, audit_status_name
select 
	concat(
		usr.first_name,
		' ',
		usr.last_name
	) auditor_name,
	lu1.display_text audit_status_name,
	count(*) total_audit_counts
from
	public.audit_schedules aud_sch
left join
	public.audit_schedule_members aud_sch_mem
on
	aud_sch.audit_schedule_id = aud_sch_mem.audit_schedule_id
left join
	public.users usr
on
	aud_sch_mem.user_id = usr.user_id
left join
	public.lookups lu1
on 
	aud_sch.audit_schedule_status_id = lu1.lookup_id
where
	aud_sch_mem.involvement_type_name  = 'AUDITOR'
group by
	auditor_name, audit_status_name

-- Note: Would it would be good if we add a unique constraint on columns (audit_schedule_id,involvement_type_name,user_id) in table audit_schedule_members
-- to prevent redundancy like audit_schedule_member_id : 9 and 11 (same audit_schedule_id, involvement_type_name and user_id)?