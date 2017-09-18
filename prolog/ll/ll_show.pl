:- module(
  ll_show,
  [
    export_uri/1, % +Uri
    show_uri/1    % +Uri
  ]
).

/** <module> LOD Laundromat: Show

@author Wouter Beek
@version 2017/09
*/

:- use_module(library(apply)).
:- use_module(library(atom_ext)).
:- use_module(library(date_time)).
:- use_module(library(debug)).
:- use_module(library(dict_ext)).
:- use_module(library(graph/dot)).
:- use_module(library(lists)).
:- use_module(library(ll/ll_generics)).
:- use_module(library(ll/ll_seedlist)).
:- use_module(library(stream_ext)).





%! export_uri(+Uri:atom) is det.
%! export_uri(+Uri:atom, +Format:atom) is det.
%
% Exports the LOD Laundromat job for the given URI to a PDF file, or
% to a file in some other Format.

export_uri(Uri) :-
  export_uri(Uri, pdf).


export_uri(Uri, Format) :-
  uri_hash(Uri, Hash),
  file_name_extension(Hash, Format, File),
  seed(Hash, Seed),
  setup_call_cleanup(
    graphviz(dot, ProcIn, Format, ProcOut),
    dot_view(ProcIn, Seed),
    close(ProcIn)
  ),
  setup_call_cleanup(
    open(File, write, Out),
    copy_stream_type(ProcOut, Out),
    close(Out)
  ).



%! show_uri(+Uri:atom) is det.
%! show_uri(+Uri:atom, +Program:atom) is det.
%
% Shows the LOD Laundromat job for the given URI in X11, or in some
% other Program.

show_uri(Uri) :-
  show_uri(Uri, x11).


show_uri(Uri, Program) :-
  uri_hash(Uri, Hash),
  seed(Hash, Seed),
  setup_call_cleanup(
    graphviz(dot, ProcIn, Program),
    dot_view(ProcIn, Seed),
    close(ProcIn)
  ).





% GENERICS %

dot_view(Out, Seed) :-
  _{http: HttpMeta} :< Seed,
  % begin
  format(Out, 'digraph g {\n', []),
  debug(dot, 'digraph g {\n', []),
  dot_seed(Out, Seed, SeedId),
  % HTTP
  maplist(dot_hash, HttpMeta, HttpIds1),
  maplist(http_meta_attrs, HttpMeta, HttpOptions),
  maplist(dot_node(Out), HttpIds1, HttpOptions),
  reverse(HttpIds1, HttpIds2),
  dot_linked_list(Out, HttpIds2, FirstId-LastId),
  dot_link(Out, SeedId, FirstId),
  % children
  dict_get(children, Seed, [], ChildPointers),
  maplist(seed, ChildPointers, Children),
  maplist(dot_seed(Out), Children, ChildIds),
  maplist(dot_link(Out, LastId), ChildIds),
  % end
  format(Out, '}\n', []),
  debug(dot, '}\n', []).

dot_link(Out, ParentId, ChildId) :-
  format(Out, '  ~a -> ~a;\n', [ParentId,ChildId]),
  debug(dot, '  ~a -> ~a;\n', [ParentId,ChildId]).

dot_linked_list(Out, [FirstId|NodeIds], FirstId-LastId) :-
  dot_linked_list_(Out, [FirstId|NodeIds], LastId).

dot_linked_list_(_, [LastId], LastId) :- !.
dot_linked_list_(Out, [H1,H2|T], LastId) :-
  format(Out, '  ~a -> ~a;\n', [H1,H2]),
  debug(dot, '  ~a -> ~a;\n', [H1,H2]),
  dot_linked_list_(Out, [H2|T], LastId).

dot_seed(Out, Seed, SeedId) :-
  dot_hash(Seed, SeedId),
  (   _{archive: ArchiveMeta, content: ContentMeta} :< Seed
  ->  format(Out, '  ~a [label=<~w,~w>];\n', [SeedId,ArchiveMeta,ContentMeta]),
      debug(dot, '  ~a [label=<~w,~w>];\n', [SeedId,ArchiveMeta,ContentMeta])
  ;   _{added: Added, uri: Uri} :< Seed
  ->  dt_label(Added, AddedLabel),
      format(Out, '  ~a [label=<Added: ~w<BR/>~w>];\n', [SeedId,AddedLabel,Uri]),
      debug(dot, '  ~a [label=<Added:~w,~w>];\n', [SeedId,AddedLabel,Uri])
  ).

http_header_label(Key-Values, Label) :-
  atom_capitalize(Key, CKey),
  atomics_to_string(Values, "; ", Value),
  format(string(Label), "~s: ~s", [CKey,Value]).

% The second argument is an options list, as expected by dot_node/3.
http_meta_attrs(HttpMeta, [label(Label),shape(box)]) :-
  http{
    headers: HeadersDict,
    status: Status,
    uri: Uri,
    version: version{major: Major, minor: Minor},
    walltime: Walltime
  } :< HttpMeta,
  dict_pairs(HeadersDict, HeaderPairs),
  maplist(http_header_label, HeaderPairs, HeaderLabels),
  atomics_to_string(HeaderLabels, "<BR/>", HeaderLabel),
  format(
    string(Label),
    "~d HTTP ~d/~d ~a<BR/>~s<BR/>~d mili-seconds",
    [Status,Major,Minor,Uri,HeaderLabel,Walltime]
  ).
