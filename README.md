# bender-proto

An _external identifier binding_ service protocol. Implemented by [bender](https://github.com/valitydev/bender).

## What?

Glad you asked. This protocol describes a service which deals with _binding_ abstraction. A _binding_ ties some _external identifier_ (e.g. identifier of some object or process in some third-party system) with a single uniform and predictable _internal identifier_, and does this _uniquely_: there should no more than one such binding for each external identifier.

## Why?

* You want to guarantee _idempotency_ of your system.

    You should tell your clients to include some form of _external identifier_ or _idempotency key_ when interacting with your system's API. This service will make sure that you'll end up with the same _internal identifier_, no matter how many identical requests you end up receiving.

* ...And also you want _predictable_ identifiers.

    In other words you want to have, for example, plain 64-bit counter for an identifier internally, no matter how diverse your clients' identifiers are.

* ...And also you want to spot _conflicting_ requests with same external identifiers.

    For that you might compute, for example, some stable hash of the request data and associate it with a binding as a _context_. Service guarantees that only the first actor who actually creates a binding (the _winner_) will have its context persisted. Other actors will see winner's context in service responses.
