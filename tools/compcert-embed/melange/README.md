The Melange build of the embed package, enabled with `COMPCERT_MELANGE=true`
(it needs `melc`):

    COMPCERT_MELANGE=true dune build ./melange/bind

Nothing here changes the native or js_of_ocaml build. The CompCert sources are
copied from `src/` rather than duplicated, and three modules that Melange does
not provide are supplied by `shims/` (`Str`, `Unix`) and `vendor/menhirLib`
(the menhirLib of the version that generated the parser).
