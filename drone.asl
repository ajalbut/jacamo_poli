// specific plans for drones
// Drone é o mestre, coordena as ações dos demais.

!run.

+!run
<-	
	!wait_skip(pricedJob(JobId,Storage,Begin,End,Reward,Items));
    .print(JobId,Storage,Begin,End,Reward,Items);
    !provide_job_items(Items);
    //!retrieve_stored_items;
    !assemble_job_items(Items);
    //!deliver_job_items(Items);
    //!deliverJob(JobId);	
	!skip_forever;    
.
