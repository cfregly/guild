%% Copyright 2016-2017 TensorHub, Inc.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(guild_eval_cmd).

-export([parser/0, main/2]).

parser() ->
    cli:parser(
      "guild evaluate",
      "[OPTION]... [RUNDIR]",
      "Evaluate a trained model in RUNIDR or the latest using --latest-run.\n"
      "\n"
      "Use 'guild list-runs' to list runs that can be used for RUNDIR.\n"
      "\n"
      "The model applicable to the run must have an evaluate operation "
      "operation defined.",
      eval_options()
      ++ guild_cmd_support:project_options([flag_support, latest_run]),
      [{pos_args, {0, 1}}]).

eval_options() ->
    [{preview, "--preview", "print evaluate details but do not train", [flag]}].

%% ===================================================================
%% Main
%% ===================================================================

main(Opts, Args) ->
    eval_or_preview(init_op(Opts, Args), Opts).

init_op(Opts, Args) ->
    {Run, Project, Model, Runtime} = guild_cmd_support:run_for_args(Args, Opts),
    guild_runtime:init_eval_op(Runtime, Run, Model, Project).

eval_or_preview({ok, Op}, Opts) ->
    case proplists:get_bool(preview, Opts) of
        false -> eval(Op);
        true  -> preview(Op)
    end;
eval_or_preview({error, Err}, _Opts) ->
    init_op_error(Err).

init_op_error(evaluatable) ->
    guild_cli:cli_error(
      "model does not support an evaluate operation\n"
      "Try 'guild evaluate --help' for more information.");
init_op_error(Err) ->
    guild_cli:cli_error(guild_cmd_support:runtime_error_msg(Err)).

eval(Op) ->
    guild_cmd_support:exec_operation(guild_eval_op, Op).

preview(Op) ->
    guild_cli:out_par("This command will use the settings below.~n~n"),
    guild_cmd_support:preview_op_cmd(Op).
