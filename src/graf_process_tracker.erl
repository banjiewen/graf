-module(graf_process_tracker).
-behaviour(gen_server).

-export([
    track/1,
    track/2
]).

-export([
    start_link/0,
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    code_change/3,
    terminate/2
]).

-record(st, {
    tracked
}).

-spec track(any()) -> ok.
track(Name) ->
    track(self(), Name).

-spec track(pid(), any()) -> ok.
track(Name, Pid) ->
    gen_server:cast(?MODULE, {track, Name, Pid}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #st{tracked = dict:new()}}.

handle_call(Msg, _From, State) ->
    {stop, {unknown_call, Msg}, error, State}.

handle_cast({track, Pid, Name}, #st{tracked=Tracked}=State) ->
    graf:increment_counter(Name),
    Ref = erlang:monitor(process, Pid),
    {noreply, State#st{tracked=dict:store(Ref, Name, Tracked)}};
handle_cast(Msg, State) ->
    {stop, {unknown_cast, Msg}, State}.

handle_info({'DOWN', Ref, _, _, _}, #st{tracked=Tracked}=State) ->
    Name = dict:fetch(Ref, Tracked),
    graf:decrement_counter(Name),
    {noreply, State#st{tracked=dict:erase(Ref, Tracked)}};
handle_info(Msg, State) ->
    {stop, {unknown_info, Msg}, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
