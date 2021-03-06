-module(rule_parser).

-export([parse/1]).

parse(Bin) ->
    Tokens = tokens(Bin),
    rules(Tokens).


tokens(<<>>) ->
    [];
tokens(<<C, Bin/binary>>)
  when C =:= $ ; C =:= $\n ->
    tokens(Bin);
tokens(<<${, Bin/binary>>) ->
    ['{'|tokens(Bin)];
tokens(<<$}, Bin/binary>>) ->
    ['}'|tokens(Bin)];
tokens(<<$(, Bin/binary>>) ->
    ['('|tokens(Bin)];
tokens(<<$), Bin/binary>>) ->
    [')'|tokens(Bin)];
tokens(<<$,, Bin/binary>>) ->
    [','|tokens(Bin)];
tokens(<<$., Bin/binary>>) ->
    ['.'|tokens(Bin)];
tokens(<<$:, Bin/binary>>) ->
    [':'|tokens(Bin)];
tokens(<<C, Bin/binary>>)
  when $a =< C, C =< $z ->
    {A, Bin1} = name(C, Bin),
    [{atom, A}|tokens(Bin1)];
tokens(<<C, Bin/binary>>)
  when $A =< C, C =< $Z ->
    {A, Bin1} = name(C, Bin),
    [{var, A}|tokens(Bin1)];
tokens(<<C, Bin/binary>>)
  when $_ =:= C ->
    {A, Bin1} = name(C, Bin),
    [{ignore, A}|tokens(Bin1)].


name(C, Bin) ->
    {S, Bin1} = name(Bin),
    {list_to_atom([C|S]), Bin1}.

name(<<C, Bin/binary>>)
  when $a =< C, C =< $z;
       $A =< C, C =< $Z;
       $0 =< C, C =< $9;
       C =:= $_ ->
    {S, Bin1} = name(Bin),
    {[C|S], Bin1};
name(Bin) ->
    {[], Bin}.


rules([]) ->
    [];
rules(List) ->
    {H, List1} = rule(List),
    T = rules(List1),
    [H|T].


rule(List) ->
    {{term, _, _}=Head, [':'|List1]} = term(List),
    {Body, List2} = terms('.', List1),
    {{clause, Head, Body}, List2}.


term([{atom, A}, '{'|List]) ->
    {Terms, List1} = terms('}', List),
    {{tuple, A, Terms}, List1};
term([{atom, A}, '('|List]) ->
    {Terms, List1} = terms(')', List),
    {{term, A, Terms}, List1};
term([{atom, A}|List]) ->
    {A, List};
term([{var, _} = V|List]) ->
    {V, List};
term([{ignore, _} = I|List]) ->
    {I, List}.


terms(End, List) ->
    {H, List1} = term(List),
    case List1 of
        [','|List2] ->
            {T, List3} = terms(End, List2); 
        [End|List3] ->
            T = []
    end,
    {[H|T], List3}.
