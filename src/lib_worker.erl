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
	 load_start/2
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
		   {ok,Paths}=rd:call(catalog,get_info,[paths,ApplicationId],5000),
		   {ok,App}=rd:call(catalog,get_info,[app,ApplicationId],5000),
		   [code:add_patha(Path)||Path<-Paths],
		   ok=application:load(App),
		   ok=application:start(App),
		   
		   LoadStartId=erlang:system_time(nanosecond),
		   LoadStartInfo=#{application_id=>ApplicationId,
				   app=>App,
				   load_start_id=>LoadStartId,
				   time=>{date(),time}
				  },
		   {ok,LoadStartInfo}
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
is_member(Key,Value,MapList)->
    R=[{true,Map}||Map<-MapList,
		 Value==maps:get(Key,Map)],
    case R of
	[]->
	    false;
	_ ->
	    true
    end.
