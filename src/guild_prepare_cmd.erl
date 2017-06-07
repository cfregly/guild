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

-module(guild_prepare_cmd).

-export([parser/0, main/2]).

parser() ->
    cli:parser(
      "guild prepare",
      "[OPTION]... [MODEL]",
      "Prepares MODEL for training if specified, otherwise prepares the "
      "default model.\n"
      "\n"
      "The default model is the first model defined in the project config.\n"
      "\n"
      "Models are prepared by their configured 'prepare' operation, if "
      "specified. If the specified model doesn't define a prepare operation, "
      "the command exits with an error message.",
      prepare_options() ++ guild_cmd_support:project_options([flag_support]),
      [{pos_args, {0, 1}}]).

prepare_options() ->
    [{preview, "--preview", "print training details but do not train", [flag]}].

%% ===================================================================
%% Main
%% ===================================================================

main(Opts, Args) ->
    prepare_or_preview(init_op(Opts, Args), Opts).

init_op(Opts, Args) ->
    Project = guild_cmd_support:project_from_opts(Opts),
    Model = guild_cmd_support:model_or_resource_section_for_args(Args, Project),
    guild_tensorflow_runtime:init_prepare_op(Model, Project).

prepare_or_preview({ok, Op}, Opts) ->
    case proplists:get_bool(preview, Opts) of
        false -> prepare(Op);
        true  -> preview(Op)
    end;
prepare_or_preview({error, Err}, _Opts) ->
    init_op_error(Err).

init_op_error(preparable) ->
    guild_cli:cli_error(
      "model does not support a prepare operation\n"
      "Try 'guild prepare --help' for more information.").

prepare(Op) ->
    guild_cmd_support:exec_operation(guild_prepare_op, Op).

preview(Op) ->
    guild_cli:out_par("This command will use the settings below.~n~n"),
    guild_cmd_support:preview_op_cmd(Op).
