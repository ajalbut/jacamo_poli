
// unifies tools the agent is able (by its role), but does not have
required_tool(T) :-
   role(_,_,_,_,Tools) & 
   .member(T,Tools) &
   not item(T,_)
.

find_shop(ItemId, ShopId) :-
	shop(ShopId,_,_,Items) &
	.member(item(ItemId,Price,Amount,_), Items)
.

find_available_storage(StorageId, Load) :-
	storage(StorageId, Lat, Long, Price, TotCap, UsedCap, Items) &
	TotCap - UsedCap > Load
.

find_storage(StorageId, Items) :-
	storage(StorageId, Lat, Long, Price, TotCap, UsedCap, Items) 
	& not .empty(Items)
.
	
find_agent_with_capacity(Capacity, AgentId) :-
	entity(AgentId,"A", Lat, Lon, Role) //& role(RoleName, S, C, B, T) //& C > Capacity 
.

find_workshop(WorkshopId) :-
	workshop(WorkshopId, Lat, Long, Price)
.