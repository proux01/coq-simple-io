# Purely functional IO for Coq [![Build Status](https://travis-ci.org/Lysxia/coq-simple-io.svg?branch=master)](https://travis-ci.org/Lysxia/coq-simple-io)

## Hello World in Coq

```coq
From SimpleIO Require Import SimpleIO.
From Coq Require Import String.
#[local] Open Scope string_scope.

Definition main : IO unit :=
  print_endline "Hello, world!".

RunIO main.
```

The `coq-simple-io` library provides tools to implement IO programs directly in Coq, in a
similar style to Haskell.

- IO monad
- Bindings to OCaml standard library
- `RunIO` command for running programs

Facilities for formal verification are not included.
There is no canonical way to describe the effects of the arbitrary foreign
constructs that this library allows, so this library commits to none.

A possible workflow is to generalize your program to any monad with a
certain interface, specialize it to a mathematical monad (*e.g.*, state)
for formal verification, and to IO for execution.
[coqffi](https://github.com/coq-community/coqffi) provides a toolchain for
generating such interfaces from OCaml interfaces.

## Installation

### From OPAM

```
opam install coq-simple-io
```

### From this repository as a local package

```
# Clone this repository
git clone https://github.com/Lysxia/coq-simple-io

# Register it with opam (the last argument is the path to the repo)
opam pin add coq-simple-io ./coq-simple-io
```

## Documentation

The documentation of the latest released version is available on website at
https://lysxia.github.io/coq-simple-io/toc.html

Consult the [OCaml user manual](https://caml.inria.fr/pub/docs/manual-ocaml/)
for detailed description of extracted code.

## Interface

To use this library:

```coq
Require Import SimpleIO.SimpleIO.

(* And to use the monadic notations: *)
Import IO.Notations.
Local Open Scope io_scope.

(* Equivalent notations can be found ext-lib, using its [Monad] type class. *)
```

Combinators for IO actions.

```coq
Parameter IO : Type -> Type.

Module IO.

Parameter ret : forall {a}, a -> IO a.
Parameter bind : forall {a b}, IO a -> (a -> IO b) -> IO b.
Parameter fix_io : forall {a b}, ((a -> IO b) -> (a -> IO b)) -> a -> IO b.
(* etc. *)

Module Notations.
Notation "c >>= f" := (bind c f)
Notation "f =<< c" := (bind c f)
Notation "x <- c1 ;; c2" := (bind c1 (fun x => c2))
Notation "e1 ;; e2" := (_ <- e1%io ;; e2%io)%io
Notation delay io := (delay_io (fun _ => io)).
End Notations.

End IO.
```

## Defining IO actions

The `IO` type extracts to the following definition in OCaml:

```ocaml
(* Implicitly [forall r, (a -> r) -> r]. *)
type 'a coq_IO = ('a -> Obj.t) -> Obj.t
```

So an effectful function `f : t -> u -> v` in OCaml can be wrapped
as a Coq function `f : t -> u -> IO v` in the following way:

```coq
Parameter f : t -> u -> IO v.
Extract Constant f => "fun a b k -> k (f a b)".
```

Basically, add an extra parameter `k` and apply it to the OCaml function call.

This boilerplate can also be generated from OCaml interfaces using
[coqffi](https://github.com/coq-community/coqffi).

## Library organization

The source code can be found under `src/`.

- `SimpleIO.SimpleIO`: Reexports default modules.

### Default modules

The following modules are imported with `SimpleIO.SimpleIO`.

- `SimpleIO.IO_Monad`: Definition of `IO` and basic combinators.
- `SimpleIO.IO_Stdlib`: Wrappers around `Stdlib` from OCaml's standard library.
- `SimpleIO.IO_StdlibAxioms`: Basic theory for pure `Stdlib` functions.
- `SimpleIO.IO_Exceptions`: Catch common exceptions.
- `SimpleIO.IO_RawChar`: Utilities that rely on `ExtrOcamlString`.
- `SimpleIO.IO_String`: Operations on OCaml strings.

### Auxiliary modules

The following module can be imported separately.
They correspond to modules from the OCaml standard library.

- `SimpleIO.IO_Bytes`: Mutable byte sequences.
- `SimpleIO.IO_Random`: Pseudo-random number generators (PRNG).
- `SimpleIO.IO_Float`: Floating-point arithmetic.
- `SimpleIO.IO_Unix`: Interface to the Unix system.
- `SimpleIO.IO_Sys`: System interface.

### Unsafe modules

- `SimpleIO.IO_Unsafe`: Unsafe operations.
- `SimpleIO.IO_UnsafeNat`: `Pervasives` functions adapted to `nat`
  (unsafety because of overflow and underflow).

## Related

- [coqffi](https://github.com/coq-community/coqffi)
- [Ynot](https://github.com/ynot-harvard/ynot)
- [Coq.io](http://coq.io)
