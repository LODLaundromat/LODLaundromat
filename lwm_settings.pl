:- module(
  lwm_settings,
  [
    lwm_authority/1, % ?Authority:atom
    lwm_scheme/1, % ?Scheme:atom
    lwm_version_directory/1, % -Directory:atom
    lwm_version_graph/1, % -Graph:iri
    lwm_version_number/1 % ?Version:positive_integer
  ]
).

/** <module> LOD Washing Machine: generics

Generic predicates for the LOD Washing Machine.

@author Wouter Beek
@version 2014/06, 2014/08
*/

:- use_module(library(filesex)).
:- use_module(library(uri)).

:- use_module(plSparql(sparql_db)).

%! lwm_sparql_endpoint(+Endpoint:atom) is semidet.
%! lwm_sparql_endpoint(-Endpoint:atom) is multi.

:- dynamic(lwm_sparql_endpoint/1).

:- initialization(init_lwm_sparql_endpoints).



%! lwm_authority(+Authortity:atom) is semidet.
%! lwm_authority(-Authortity:atom) is det.

lwm_authority('lodlaundromat.org').


%! lwm_scheme(+Scheme:atom) is semidet.
%! lwm_scheme(-Scheme:oneof([http])) is det.

lwm_scheme(http).


%! lwm_version_directory(-Directory:atom) is det.
% Returns the absolute directory for the current LOD Washing Machine version.

lwm_version_directory(Dir):-
  % Place data documents in the data subdirectory.
  absolute_file_name(data(.), DataDir, [access(write),file_type(directory)]),

  % Add the LOD Washing Machine version to the directory path.
  lwm_version_number(Version1),
  atom_number(Version2, Version1),
  directory_file_path(DataDir, Version2, Dir),
  make_directory_path(Dir).


%! lwm_version_graph(-Graph:iri) is det.

lwm_version_graph(Graph):-
  lwm_version_number(Version),
  atom_number(Fragment, Version),
  uri_components(
    Graph,
    uri_components(http,'lodlaundromat.org',_,_,Fragment)
  ).


%! lwm_version_number(+Version:positive_integer) is semidet.
%! lwm_version_number(-Version:positive_integer) is det.

lwm_version_number(11).



% Initialization.

init_lwm_sparql_endpoints:-
  init_cliopatria_endpoint,
  init_virtuoso_endpoint.

init_cliopatria_endpoint:-
  assert(lwm_sparql_endpoint(cliopatria)),
  sparql_register_endpoint(
    cliopatria,
    uri_components(http,'localhost:3020','/',_,_),
    cliopatria
  ).

init_virtuoso_endpoint:-
  assert(lwm_sparql_endpoint(virtuoso)),
  sparql_register_endpoint(
    virtuoso,
    uri_components(http,localhost,'/',_,_),
    virtuoso
  ).
