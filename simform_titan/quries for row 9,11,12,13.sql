---------------------------> 9 PROCESS_AUTOMATION (Workflow App) <---------------------------
-- Query for card
select
	process_tailoring_id, 	lu1.display_text project_methodology, 	lu2.display_text phase,
	usr.first_name || ' ' || usr.last_name owner,	usr.user_name_email owner_email  
from 
	public.process_tailorings pt
left join 
	public.lookups lu1
on 
	pt.project_methodology_id = lu1.lookup_id
left join 
	public.lookups lu2
on 
	pt.phase_id = lu2.lookup_id
left join 
	public.users usr
on 
	pt.project_owner_user_id = usr.user_id
;

-- Query for record
select
	process_tailoring_id , 
	doc_name, 
	lu1.display_text default_applicability, 
	owner_requested_applicability_id,
	lu2.display_text project_owner_approval_status,
	project_owner_tailoring_remarks,
	project_owner_tailoring_request_date,
	usr1.user_name_email approver_user,
	lu3.display_text approver_approval_status,
	approver_tailoring_remarks,
	approver_tailoring_action_date
from 
	public.process_tailorings pt
left join 
	public.lookups lu1
on 
	pt.default_applicability_id = lu1.lookup_id
left join 
	public.lookups lu2
on 
	pt.project_owner_approval_status_id = lu2.lookup_id
left join 
	public.users usr1
on 
	pt.approver_user_id = usr1.user_id
left join 
	public.lookups lu3
on 
	pt.approver_approval_status_id = lu3.lookup_id
;

---------------------------> 11 TRAINING_PORTAL <---------------------------
-- Note:
-- please add foregin_key constraint on cloumn training_recommendations.request_source_type_id referencing to public.lookups(lookup_id)

select 
	t_rcmd.training_recommendation_id , training_title,
	lu1.display_text request_source_type, 
	request_date_time,
	usr1.first_name || ' ' || usr1.last_name recommended_user,
	usr2.first_name || ' ' || usr1.last_name for_user
from 
	public.training_recommendations t_rcmd
left join 
	public.training_repositories t_repo
on
	t_rcmd.training_repository_id  = t_repo.training_repository_id 
left join 
	public.lookups lu1
on 
	t_rcmd.request_source_type_id = lu1.lookup_id
left join 
	public.users usr1
on 
	t_rcmd.recommender_user_id = usr1.user_id
left join 
	public.users usr2
on 
	t_rcmd.for_user_id = usr2.user_id
order by 
	training_title
;

---------------------------> 12 TRAINING_PORTAL <---------------------------
-- Query 1
select 
	training_title,	schedule_title,	short_description 
from 
	training_schedules ts
left join 
	training_repositories tr
on 
	ts.training_repository_id = tr.training_repository_id
;

-- Query 2
select 
	trainer_user_id_list,
	support_user_id_list
from
	public.training_schedules
;

-- Query 3
select
	training_schedule_batch_id , schedule_title,
	batch_title, tsb.plan_start_date, tsb.plan_end_date
from 
	public.training_schedule_batches tsb
left join
	public.training_schedules ts
using(training_schedule_id)
;

-- Query 4
select usr.first_name || ' ' || usr.last_name  training_schedule_by_user
from
	public.training_schedules ts
left join
	public.users usr
on 
	usr.user_id = ts.training_schedule_by_user_id
;

-- Query 5
select 
	lms_source_url ,require_pre_evaluation, require_post_evaluation,lms_pre_test_url,lms_post_test_url
from 
	public.training_repositories
;

-- Complete query
select 
	training_title,	schedule_title,	short_description,trainer_user_id_list,support_user_id_list,
	training_schedule_batch_id,	batch_title, tsb.plan_start_date, tsb.plan_end_date,
	usr.first_name || ' ' || usr.last_name  training_schedule_by_user,
	lms_source_url ,require_pre_evaluation, require_post_evaluation,lms_pre_test_url,lms_post_test_url
from 
	training_schedules ts
left join 
	training_repositories tr
on 
	ts.training_repository_id = tr.training_repository_id
left join
	public.training_schedule_batches tsb
on
	ts.training_schedule_id = tsb.training_schedule_id
left join
	public.users usr
on 
	usr.user_id = ts.training_schedule_by_user_id
;

---------------------------> 13 ACTION_TRACKER <---------------------------
select 
	action_tracker_id,
	action_scope_name,
	lu1.display_text primary_category,
	lu2.display_text secondary_category,
	lu3.display_text priority_id,
	action_title,
	plan_end_date,
	lu4.display_text action_status
from 
	public.action_trackers act_trk
left join
	( select action_instance_id,action_scope_name from public.action_instances) act_inst
on
	act_trk.tracker_instance_id = act_inst.action_instance_id
left join
	public.lookups lu1
on
	act_trk.primary_category_id = lu1.lookup_id 
left join
	public.lookups lu2
on
	act_trk.secondary_category_id = lu2.lookup_id
left join
	public.lookups lu3
on
	act_trk.priority_id = lu3.lookup_id
left join
	public.lookups lu4
on
	act_trk.action_status_id = lu4.lookup_id
order by
	tracker_instance_id
;
