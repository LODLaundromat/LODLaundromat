%:- set_prolog_flag(optimise, true).
:- set_prolog_flag(verbose, silent).

%:- use_module(library(ll/ll_debug)).
:- use_module(library(ll/ll_init)).
:- use_module(library(ll/ll_workers)).

run :-
  thread_get_message(stop).
:- run.
