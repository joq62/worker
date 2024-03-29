%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%% 
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(worker). 

-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").

-include("worker.hrl").
-include("worker.resource_discovery").


%% API

-export([
	 load_start/1,
	 stop_unload/1,
	 restart_application/1,
%	 is_loaded/1,
%	 is_running/1,
	 loaded/0,
	 running/0
	]).

-export([

	]).

%% admin




-export([
	 get_supervisor_pid/0,
	 get_state/0,
	 get_pid/0,
	 start/0,
	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).

%%-- Data  load_start_info
% maps: ApplicationId,App,Git,time
%
%
		     
-record(state, {
		load_start_info	        
	       }).

%%%===================================================================
%%% API
%%%===================================================================
%	 load_start/1,
%	 stop_unload/1
%	 loaded/0,
%	 running/0

%%--------------------------------------------------------------------
%% @doc
%%  Resturn the gen_server pid, used for monitoring 
%% @end
%%--------------------------------------------------------------------
-spec get_pid() -> 
	  {ok,Pid :: pid()} | {error, Reason :: term()}.
get_pid() ->
    gen_server:call(?SERVER,{get_pid},infinity).
%--------------------------------------------------------------------
%% @doc
%%  Resturn the superviso pid, used for monitoring 
%% @end
%%--------------------------------------------------------------------
-spec get_supervisor_pid() -> 
	  {ok,Pid :: pid()} | {error, Reason :: term()}.
get_supervisor_pid() ->
    gen_server:call(?SERVER,{get_supervisor_pid},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Load and starts application ApplicationId  
%% Will also do a resources discovery call 
%% @end
%%--------------------------------------------------------------------
-spec load_start(ApplicationId :: string()) -> 
	  {ok,LoadStartId :: integer()} | {error, Reason :: term()}.
load_start(ApplicationId) ->
    gen_server:call(?SERVER,{load_start,ApplicationId},infinity).
%%--------------------------------------------------------------------
%% @doc
%% stop and unload stops the application that is related to LoadStartId
%% Will also do a resources discovery 
%% @end
%%--------------------------------------------------------------------
-spec stop_unload(LoadStartId :: string()) -> 
	  ok | {error, Reason :: term()}.
stop_unload(LoadStartId) ->
    gen_server:call(?SERVER,{stop_unload,LoadStartId },infinity).


%	 loaded/0,
%	 running/0
%%--------------------------------------------------------------------
%% @doc
%% Resturn loaded applications 
%% 
%% @end
%%--------------------------------------------------------------------
-spec loaded() -> 
	  {ok,ListOfApps :: atom()} | {error, Reason :: term()}.
loaded() ->
    gen_server:call(?SERVER,{loaded},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Resturn running applications 
%% 
%% @end
%%--------------------------------------------------------------------
-spec running() -> 
	  {ok,ListOfApps :: atom()} | {error, Reason :: term()}.
running() ->
    gen_server:call(?SERVER,{running},infinity).

%%--------------------------------------------------------------------
%% @doc
%%  
%% 
%% @end
%%--------------------------------------------------------------------
start()->
    application:start(?MODULE).


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec get_state() -> State::term().
get_state()-> 
    gen_server:call(?SERVER, {get_state},infinity).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong | Error::term().
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).


%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


%stop()-> gen_server:cast(?SERVER, {stop}).
stop()-> gen_server:stop(?SERVER).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    ?LOG_NOTICE("Server started ",[?MODULE]),
    {ok, #state{
	    load_start_info=[]	        
	   },0}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.

    
handle_call({load_start,ApplicationId}, _From, State)->
    Result= try lib_worker:load_start(ApplicationId,State#state.load_start_info) of
		{ok,CreateResult}->
		    {ok,CreateResult};
		{error,Reason}->
		    {error,Reason}
	    catch
		Event:Reason:Stacktrace ->
		    {Event,Reason,Stacktrace,?MODULE,?LINE}
	    end,
    Reply=case Result of
	      {ok,LoadStartInfo}->
		  NewState=State#state{load_start_info=[LoadStartInfo|State#state.load_start_info]},
		  {ok,LoadStartInfo,NewState};
	      ErrorEvent->
		  io:format("ErrorEvent ~p~n",[{ErrorEvent,?MODULE,?LINE}]),
		  NewState=State,
		  ErrorEvent
	  end,
    {reply, Reply, NewState};

    
handle_call({stop_unload,LoadStartId}, _From, State)->
    Result= try lib_worker:stop_unload(LoadStartId,State#state.load_start_info) of
		{ok,CreateResult}->
		    {ok,CreateResult};
		{error,Reason}->
		    {error,Reason}
	    catch
		Event:Reason:Stacktrace ->
		    {Event,Reason,Stacktrace,?MODULE,?LINE}
	    end,
    Reply=case Result of
	      {ok,LoadStartInfo}->
		  NewState=State#state{load_start_info=lists:delete(LoadStartInfo,State#state.load_start_info)},
		  {ok,LoadStartInfo,NewState};
	      ErrorEvent->
		  io:format("ErrorEvent ~p~n",[{ErrorEvent,?MODULE,?LINE}]),
		  NewState=State,
		  ErrorEvent
	  end,
    {reply, Reply, NewState};


%%--------------------------------------------------------------------



handle_call({get_state}, _From, State) ->
    Reply=State,
    {reply, Reply, State};

handle_call({get_pid}, _From, State) ->
    Reply={ok,self()},
    {reply, Reply, State};

handle_call({get_supervisor_pid}, _From, State) ->
    SupervisorPid=worker_sup:get_pid(),
    Reply={ok,SupervisorPid},
    {reply, Reply, State};


handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call(UnMatchedSignal, From, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast({stop}, State) ->
    
    {stop,normal,ok,State};

handle_cast(UnMatchedSignal, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.

handle_info(timeout, State)->
  
    ok=initial_trade_resources(),
    
    {noreply, State};


handle_info({'DOWN',MonitorRef,process,Pid,shutdown}, State)->
    io:format("'DOWN',MonitorRef,process,Pid ~p~n",[{'DOWN',MonitorRef,process,Pid,shutdown,?MODULE,?LINE}]),
    
    {noreply, State};

handle_info({'DOWN',MonitorRef,process,Pid,Info}, State)->
    io:format("'DOWN',MonitorRef,process,Pid,Info ~p~n",[{'DOWN',MonitorRef,process,Pid,Info,?MODULE,?LINE}]),
    Result= try lib_worker:restart(MonitorRef,State#state.load_start_info) of
		{ok,CreateResult}->
		    {ok,CreateResult};
		{error,Reason}->
		    {error,Reason}
	    catch
		Event:Reason:Stacktrace ->
		    {Event,Reason,Stacktrace,?MODULE,?LINE}
	    end,
    NewState=case Result of
		 {ok,{LoadStartInfo,UpdatedLoadStartInfo}}->
		     State#state{load_start_info=[UpdatedLoadStartInfo|lists:delete(LoadStartInfo,State#state.load_start_info)]}; 
		 ErrorEvent->
		     io:format("ErrorEvent ~p~n",[{ErrorEvent,?MODULE,?LINE}]),
		     State
	     end,
    {noreply,NewState};

handle_info(Info, State) ->
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
restart_application(ApplicationId)->
    timer:sleep(2000),
    rpc:cast(node(),?MODULE,load_start,[ApplicationId]),
    ok.
%%--------------------------------------------------------------------
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
initial_trade_resources()->
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-?LocalResourceTuples],
    [rd:add_target_resource_type(TargetType)||TargetType<-?TargetTypes],
    rd:trade_resources(),
    timer:sleep(3000),
    ok.
