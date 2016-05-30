+simEnd
<-
	!end_round;
	!new_round;
.

+!new_round
<-  .print("-------------------- BEGIN OF NEW ROUND ----------------");
	.
	
+!end_round
<-
	.print("-------------------- END OF THE ROUND ----------------");
	.abolish(_[source(self)]);
	.abolish(_[source(X)]);
    .drop_all_intentions;
    .drop_all_desires;	
.

+charge(C) : role(Name, _, _, B, _) & C < 2 * B / 5 & not .desire(charge) <- !charge.

+lastActionResult(R) : R \== none & R \== successful <- .print("last action result: ",R).

+inFacility(FacilityId)
<-  .my_name(Me);
    .broadcast(achieve,update_location(Me,FacilityId));
. 

+item_needed(ItemId, Amount, ReqCapacity, Asker)
<-
    ?role(Name, S, C, B, T);
    .print("I am a ", Name, " my capacity is ", C);
	if(C > ReqCapacity) {
		.send(Asker, tell, item_provided(ItemId, Amount, Asker));
		.send(Asker, tell, item_needed_received);
		.print("I have the required capacity.");
		
		if(providing) {
			!wait_skip(not providing);
		}
		
		+providing;
		!provide_item(ItemId, Amount);
		-providing;
	} else {
		.send(Asker, tell, item_needed_received);
	}
	-item_needed(ItemId, Amount, ReqCapacity, Asker);
.

+!update_location(Ag,L)
<-   -ag_loc(Ag,_);
     +ag_loc(Ag,L);
.

+!all_at(Ags,Loc) : .count(.member(A,Ags) & ag_loc(A,Loc)) == .length(Ags).
+!all_at(Ags,Loc) 
<-  .findall(A, .member(A,Ags) & ag_loc(A,Loc),LAt);
    .difference(Ags,LAt,RAgs);
    ?step(S);
    .print("waiting ",RAgs," to arrive at ",Loc," -- step ",S);
    !skip;
    !all_at(Ags,Loc);
.


// waits for some belief, skip otherwise
+!wait_skip(B) : B.
+!wait_skip(B) <- !skip; !wait_skip(B).


+!skip_forever
<- !skip;
   !skip_forever;
.

+!buy_item(Item,Amount) : item(Item,A) & A >= Amount.
+!buy_item(Item,Amount) : step(_)
<-  ?find_shop(Item,S);
    !goto(S, 0);
    if (inFacility(S)) {
    	.print("ok, at ",S);
    	!buy(Item,Amount);
    	!wait_skip(item(Item,Amount));
    } 
    !buy_item(Item,Amount).
+!buy_item(Item,Amount) 
<-  .wait({+step(_)});
    !buy_item(Item,Amount).
    
+!provide_job_items(JobItems)
<-  
	.my_name(Me); 
	for (.member(item(ItemId,Amount),JobItems)) {
//		?product(ItemId, Volume, Materials);
//		ReqCapacity = Amount * Volume;
//		for (.member(X, [1,2,3,4])) {
//			if (not item_provided(ItemId, Amount, Me)) {
//				.concat("vehicle", X, XName);
//				if (XName == Me) {
					!provide_item(ItemId, Amount);
//				} else {
//					.send(XName,tell,item_needed(ItemId, Amount, ReqCapacity, Me));
//					!wait_skip(item_needed_received);
//				}
//			}
//		}
   	}
.

+!provide_item(ItemId, Amount)
<-	
	.print("Providing ", Amount, " units of ", ItemId, ".");
    ?product(ItemId, Volume, Materials);
    ?role(Name, S, C, B, T);
    ?load(L);
    .print("Item ", ItemId, " is a product with volume ", Volume);
   	if (.empty(Materials)) {
    	ReqCapacity = Amount * Volume;
   		if(C < ReqCapacity) {
    		.print("I don't hava enough capacity to carry ", Amount, " ", ItemId);
    		.print("My capacity is ", C, " and required capacity is ", ReqCapacity);
    		//.broadcast(tell, item_needed(ItemId, Amount, ReqCapacity));
    		//!wait_skip(item_provided(ItemId, 200000,_));
    		.my_name(Me);
			for (.member(X, [1,2,3,4])) {
				if (not item_provided(ItemId, Amount, Me)) {
					.concat("vehicle", X, XName);
					if (XName \== Me) {
						.send(XName,tell,item_needed(ItemId, Amount, ReqCapacity, Me));
						!wait_skip(item_needed_received);
					}
				}
			}
			-item_provided(ItemId, Amount, Me);
    	} else {
    		if(C < L + ReqCapacity) {
    			!store_load(L);
    		}
    		!buy_item(ItemId,Amount);
    	}
	} else {
		.print("To produce ", Amount, " ", ItemId, ":");
		!provide_materials(Materials, Amount);
		//!assemble_item(ItemId, Amount, Materials);
	}
	//!store_load(L);
	//!goto(workshop1, 0);
.

+!provide_materials(Materials, Amount)
<-  
	for (.member(consumed(Id, ConsAmount), Materials)) {
		.print(ConsAmount * Amount, " units of ", Id, " are consumed.");
		!provide_item(Id, ConsAmount * Amount);
    }
	for (.member(tools(Id, ReqAmount), Materials)) {
		.print(ReqAmount, " units of ", Id, " are required.");
		!provide_item(Id, ReqAmount);
    }
.

+!store_load(Load)
<-  ?find_available_storage(StorageId, Load);
	!goto(StorageId, 0);
	if (inFacility(StorageId)) {
		.print("ok, at ", StorageId);
		while (item(ItemId, Amount)) {
			.print("Storing ", Amount, " units of ", ItemId);
			!store(ItemId, Amount);
		}
	}
.

+!retrieve_stored_items
<-  
	.my_name(Me);
	?find_workshop(WorkshopId);
	for (.member(X, [1,2,3,4])) {
		.concat("vehicle", X, XName);
		if (XName == Me) {
			if (find_storage(StorageId, Items)) {
				.print(Items);
				for (.member(item(ItemId, AmStored, AmDelivered), Items)) {
					.print(StorageId, " has ", AmStored, " of ", ItemId);
				}
			}
			!goto(WorkshopId, 0);
			//!retrieve_items_in_storage(Storage);
		} else {
			.send(XName,achieve,goto(WorkshopId, 0));
			//!wait_skip(item_needed_received);
		}
	}
.

+!assemble_job_items(JobItems)
<-
  	for (.member(item(ItemId,Amount), JobItems)) {
  		?product(ItemId, Volume, Materials);
    	if (not item(ItemId, Amount) & not .empty(Materials)) {
      		!assemble_item(ItemId, Amount, Materials);					
     	}			
  	}  
.

+!assemble_item(ItemId, Amount, Materials) <-
	for (.member(consumed(ConsId, ConsAmount), Materials)) {
		.print(ConsAmount * Amount, " units of ", ConsId, " are consumed in assembly.");
		?product(ConsId, ConsVolume, ConsMats);
		if (not item(ConsId, ConsAmount * Amount) & not .empty(ConsMats)) {
			!assemble_item(ConsId, ConsAmount * Amount, ConsMats)
		}
    }
	for (.member(tools(ToolsId, ReqAmount), Materials)) {
		.print(ReqAmount, " units of ", ToolsId, " are required for assembly.");
		?product(ToolsId, ToolsVolume, ToolsMats);
		if (not item(ToolsId, ReqAmount * Amount) & not .empty(ToolsMats)) {
			!assemble_item(ToolsId, ReqAmount * Amount, ToolsMats)
		}
    }
    
    for(.range(I,1,Amount)) {
    	!assemble(ItemId);	
    }	
.
