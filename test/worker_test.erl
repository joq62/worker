%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(worker_test).      
 
-export([start/0]).

-define(TestApplicationId,"adder").
-define(TestApp,adder).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    ok=setup(),
    ok=load_start(),
%    ok=monitor_test(),
    

    io:format("Test OK !!! ~p~n",[?MODULE]),
%    timer:sleep(1000),
%    init:stop(),
    ok.


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
monitor_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
 
    Pid=erlang:whereis(?TestApp),
    Pid!{glurk},
    Ref=erlang:monitor(process,Pid),
    io:format("Pid, Ref ~p~n",[{Pid,Ref,?MODULE,?FUNCTION_NAME}]),
    
    ?TestApp:stop(),
    receive
	X->
	    %{'DOWN',#Ref<0.2478890797.869269520.10588>,process,<0.125.0>,normal}
	    io:format("X ~p~n",[{X,?MODULE,?FUNCTION_NAME}])
    end,
    



    %{'DOWN', MonitorRef, Type, Object, Info}
   
    ok.
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
load_start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    {badrpc,_}=rpc:call(node(),?TestApp,ping,[],5000),
    {ok,LoadStartInfo1,State1}=worker:load_start(?TestApplicationId),
    [rd:add_target_resource_type(TargetType)||TargetType<-[?TestApp]],
    rd:trade_resources(),
    timer:sleep(1000),
    pong=rd:call(?TestApp,ping,[],5000),
    42=rd:call(?TestApp,add,[20,22],5000),
 %   {error,["Already deployed ",?TestApplicationId]}=worker:load_start(?TestApplicationId),

   
    %% crash the application 
    
    {badrpc,_}=rd:call(?TestApp,add,[glurk,22],5000),
    
    {N,true}=check_restarted(?TestApp,100,50,false),
    io:format("is Started after N ms  ~p~n",[{N*30,?MODULE,?FUNCTION_NAME,?LINE}]),
    42=rd:call(?TestApp,add,[20,22],5000),
    %% stop_unload
    
    LoadStartId=maps:get(load_start_id,LoadStartInfo1),
    {ok,LoadStartInfo2,State2}=worker:stop_unload(LoadStartId),
    {badrpc,_}=rd:call(?TestApp,ping,[],5000),
    {badrpc,_}=rd:call(?TestApp,add,[20,22],5000),
    io:format("LoadStartInfo1 ~p~n",[{LoadStartInfo1,?MODULE,?FUNCTION_NAME}]),
    io:format("LoadStartInfo2 ~p~n",[{LoadStartInfo2,?MODULE,?FUNCTION_NAME}]),
    

    ok.

check_restarted(_App,0,_Timeout,IsStarted)->
    {0,IsStarted};
check_restarted(_App,N,_Timeout,true) ->
    {N,true};
check_restarted(App,N,Timeout,false)->
    IsStarted=case rd:call(App,ping,[],5000) of
		  pong->
		      true;
		  _->
		      timer:sleep(Timeout),
		      false
	      end,
    
    check_restarted(App,N-1,Timeout,IsStarted).
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
     
    ok.
