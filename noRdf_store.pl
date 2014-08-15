:- module(
  noRdf_store,
  [
    post_rdf_triples/1, % +Md5:atom
    store_triple/3 % +Subject
                   % +Predicate
                   % +Object
  ]
).

/** <module> no-RDF store

A small-scale and simple RDF-like store that does not use
the built-in triple store for RDF in Semweb.
This means that we can use RDF transactions + snapshots
and at the same time send small RDF messages using SPARQL Update requests.

@author Wouter Beek
@version 2014/05-2014/06, 2014/08
*/

:- use_module(library(option)).
:- use_module(library(semweb/rdf_db)).

:- use_module(plSparql(sparql_api)).

:- use_module(lwm(lwm_settings)).
:- use_module(lwm(md5)).
:- use_module(lwm_sparql(lwm_sparql_endpoint)).

%! rdf_triple(
%!   ?Subject:or([bnode,iri]),
%!   ?Predicate:iri,
%!   ?Object:or([bnode,iri,literal])
%! ) is nondet.
% Since threads load data in RDF transactions with snapshots,
% we cannot use the triple store for anything else during
% the load-save cycle of a data document.
% Therefore, we store triples that arise during this cycle
% as thread-specific Prolog assertions.

:- thread_local(rdf_triple/3).



%! post_rdf_triples(+Md5:atom) is det.
% Sends a SPARQL Update request to the LOD Laundromat Endpoint
% containing all current noRdf triples, for a particular MD5.
%
% The thread-local rdf_triple/3 statements form the contents
% of the update request.

post_rdf_triples(Md5):-
  md5_bnode_base(Md5, BaseComponents),
  post_rdf_triples0([bnode_base(BaseComponents)]).

post_rdf_triples0(Options1):-
  setup_call_cleanup(
    aggregate_all(
      set(Triple),
      rdf_triple(Triple),
      Triples
    ),
    forall(
      lwm_sparql_endpoint(Endpoint, Options2),
      (
        merge_options(Options1, Options2, Options3),
        sparql_insert_data(Endpoint, Triples, Options3)
      )
    ),
    retractall(rdf_triple(_, _, _)
  ).


rdf_triple([S,P,O]):-
  rdf_triple(S, P, O).


%! store_triple(+Subject, +Predicate, +Object) is det.

store_triple(S1, P1, O1):-
  maplist(rdf_term_map, [S1,P1,O1], [S2,P2,O2]),
  assert(rdf_triple(S2, P2, O2)).


rdf_term_map(X-Y, Z):- !,
  rdf_global_id(X:Y, Z).
rdf_term_map(literal(type(X-Y,Q)), literal(type(Z,Q))):- !,
  rdf_global_id(X:Y, Z).
rdf_term_map(X, X).

