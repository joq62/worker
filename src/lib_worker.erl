%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2024, c50
%%% @doc
%%%
%%% @end
%%% Created : 11 Jan 2024 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_worker).
 
%% API
-export([
	 load_start/2,
	 stop_unload/2
	]).

%%%===================================================================
%%% API
%%%===================================================================


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Application  part Start
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
load_start(ApplicationId,LoadStartInfoList)->
      Result=case is_member(application_id,ApplicationId,LoadStartInfoList) of
	       true->
		   {error,["Already deployed ",ApplicationId]};
	       false->
		   {ok,Paths}=rd:call(catalog,get_application_paths,[ApplicationId],5000),
		   {ok,App}=rd:call(catalog,get_application_app,[ApplicationId],5000),
		   [code:add_patha(Path)||Path<-Paths],
		   ok=application:load(App),
		   ok=application:start(App),
		   LoadStartId=erlang:system_time(nanosecond),
		   ApplicationPid=erlang:whereis(App),
		   MonitorRef=erlang:monitor(process,ApplicationPid),
		   LoadStartInfo=#{application_id=>ApplicationId,
				   app=>App,
				   application_pid=>ApplicationPid,
				   load_start_id=>LoadStartId,
				   monitor_ref=>MonitorRef,
				   time=>{date(),time()}
				  },
		   {ok,LoadStartInfo}
	   end,
    Result.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
stop_unload(LoadStartId,LoadStartInfoList)->
    Result=case key_find(load_start_id,LoadStartId,LoadStartInfoList) of
	       false->
		   {error,["Doesnt exist  ",LoadStartId]};
	       {ok,Map}->
		   ApplicationId=maps:get(application_id,Map),
		   App=maps:get(app,Map),
		   {ok,Paths}=rd:call(catalog,get_application_paths,[ApplicationId],5000),
		   ok=application:stop(App),
		   ok=application:unload(App),
		   [code:del_path(Path)||Path<-Paths],
		   {ok,Map}
	   end,
    Result.



%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
key_find(Key,Value,MapList)->
    R=[Map||Map<-MapList,
		 Value==maps:get(Key,Map)],
    Result=case R of
	       []->
		   false;
	       [Map|_]->
		   {ok,Map}
	   end,
    Result.
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
is_member(Key,Value,MapList)->
    R=[{true,Map}||Map<-MapList,
		 Value==maps:get(Key,Map)],
    Result=case R of
	       []->
		   false;
	       _ ->
		   true
	   end,
    Result.
