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

// Condições para recarga.
+charge(C) : role("truck", _, _, B, _) & C < B / 2 & not .desire(charge) <- !charge.
+charge(C) : role(Name, _, _, B, _) & C < 2 * B / 5 & not .desire(charge) <- !charge.

+lastActionResult(R) : R \== none & R \== successful <- .print("last action result: ",R).

+inFacility(FacilityId)
<-  .my_name(Me);
    .broadcast(achieve,update_location(Me,FacilityId));
. 

// Agente é informado de que outro agente precisa de um item. 
// Espera terminar tarefa atual até iniciar a próxima.
+item_needed(ItemId, Amount, ReqCapacity, Asker)
<-
    ?role(Name, S, C, B, T);
    .print("I am a ", Name, " my capacity is ", C);
	if(C > ReqCapacity) {
		.send(Asker, tell, item_provided(ItemId, Amount, Asker));
		.send(Asker, tell, item_needed_received);
		.print("I have the required capacity.");
		
		if (providing) {
			.wait({-providing});
		}
		
		+providing;
		!provide_item(ItemId, Amount);
		-providing;
	} else {
		.send(Asker, tell, item_needed_received);
	}
	-item_needed(ItemId, Amount, ReqCapacity, Asker);
.

// Orientação do mestre para todos item até a oficina para a montagem.
+!all_go_to(WorkshopId) <-
	.print("waiting");
	if (providing) {
		.wait({-providing});
	}
	.print("going");
	!goto(WorkshopId, 0);
.

+!update_location(Ag,L)
<-   -ag_loc(Ag,_);
     +ag_loc(Ag,L);
.

// Espera todos os agentes chegarem ao local desejado.
+!all_at(Ags,Loc) : .count(.member(A,Ags) & ag_loc(A,Loc)) == .length(Ags).
+!all_at(Ags,Loc) 
<-  .findall(A, .member(A,Ags) & ag_loc(A,Loc),LAt);
    .difference(Ags,LAt,RAgs);
    ?step(S);
    .print("waiting ",RAgs," to arrive at ",Loc," -- step ",S);
    !skip;
    !all_at(Ags,Loc);
.

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
    	!buy(Item,Amount);
    	!wait_skip(item(Item,Amount));
    } 
    !buy_item(Item,Amount).
+!buy_item(Item,Amount) 
<-  .wait({+step(_)});
    !buy_item(Item,Amount).
   
// Providencia os itens pedidos no contrato.    
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

// Providencia um item. Se for matéria prima, vai até uma loja e compra.
// Senão, busca e providencia as matérias primas necessárias para o item.
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
					if (not .substring(XName,Me)) {
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

// Providencia materias primas e ferramentas contidas na lista fornecida. 
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

// Armazena toda a carga do agente em questão em um depósito.
+!store_load(Load)
<-  ?find_available_storage(StorageId, Load);
	!goto(StorageId, 0);
	if (inFacility(StorageId)) {
		while (item(ItemId, Amount)) {
			.print("Storing ", Amount, " units of ", ItemId);
			!store(ItemId, Amount);
			!wait_skip(not item(ItemId, Amount));
		}
	}
.

// Recupera todos os itens armazenados em depósitos.
+!retrieve_stored_items
<-  
	.my_name(Me);
	for (.member(X, [1,2,3,4])) {
		.concat("vehicle", X, XName);
		if (XName == Me) {
			if (find_storage(StorageId, Items)) {
				.print(Items);
				for (.member(item(ItemId, AmStored, AmDelivered), Items)) {
					.print(StorageId, " has ", AmStored, " of ", ItemId);
				}
			}
			!goto(StorageId, 0);
			!retrieve_items_in_storage(StorageId);
		} else {
			.send(XName,achieve,goto(WorkshopId, 0));
			//!wait_skip(item_needed_received);
		}
	}
.

// Vai até a oficina e monta os produtos finais a serem entregues.
+!assemble_job_items(JobItems)
<-
	?find_workshop(WorkshopId);
	.my_name(Me);
	for (.member(X, [1,2,3,4])) {
		.concat("vehicle", X, XName);
		if (not .substring(XName,Me)) {
			.print("others ", XName);
			.send(XName,achieve,all_go_to(WorkshopId));
		}
	}
	!goto(WorkshopId, 0);
	if (inFacility(WorkshopId)) {
		!all_at([vehicle1,vehicle2,vehicle3,vehicle4],WorkshopId);
	  	for (.member(item(ItemId,Amount), JobItems)) {
	  		?product(ItemId, Volume, Materials);
	    	if (not item(ItemId, Amount) & not .empty(Materials)) {
	      		!assemble_item(ItemId, Amount, Materials);					
	     	}			
	  	}
  	}
.

// Monta o produto na quantidade requerida com os materiais necessários.
// Se necessário, monta também cada material, de forma recursiva.
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
