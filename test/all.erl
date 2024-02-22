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
-module(all).      
 
-export([start/0]).

-include("/home/joq62/erlang/dev/catalog/include/catalog.hrl").


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
    ok=worker_test:start(),

    io:format("Test OK !!! ~p~n",[?MODULE]),
%    timer:sleep(1000),
%    init:stop(),
    ok.


%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    ok=application:start(log),
    pong=log:ping(),
    ok=application:start(rd),
    pong=rd:ping(),

    file:del_dir_r(?MainDir),
    file:make_dir(?MainDir),

    ok=application:start(catalog),
    pong=catalog:ping(),
    CatalogResult=[catalog:clone_application_repo(ApplicationId)||ApplicationId<-lists:sort(catalog:get_all_ids())],
    []=[R||R<-CatalogResult,
	   ok=/=R],
    ok=application:start(worker),
    pong=worker:ping(),
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-[]],
    [rd:add_target_resource_type(TargetType)||TargetType<-[log,rd,catalog,worker]],
    rd:trade_resources(),
    timer:sleep(3000),
    [{catalog,{catalog,'worker_a@c50'}},{worker,{worker,'worker_a@c50'}}]=lists:sort(rd:get_all_resources()),
    
    ok.
