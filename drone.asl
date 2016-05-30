// specific plans for drones

!run.

+!run
<-	
	!wait_skip(pricedJob(JobId,Storage,Begin,End,Reward,Items));
    .print(JobId,Storage,Begin,End,Reward,Items);
    !provide_job_items(Items);
    !retrieve_stored_items;
    !assemble_job_items(Items);
    //!deliver_job_items(Items,Storage);
//    !buy_item(tool1,1);
//    !buy_item(base1,5);
//    !goto(workshop1,0);
//    !assemble(material1);
//    
//    !buy_item(base1,5);
//    !goto(workshop1,0);
//    !assemble(material1);
//    
//    .print("ok, I have material 1");
//    
//    .print("at workshop waiting to assemble...");    
//    !wait_skip( assemble_step(AS) );
//    !wait_skip( step(AS) );
//	!assist_assemble(a1);
	
	!skip_forever;    
.
