# A Filter You Can't Turn Off

Proof of concept for the article *A Filter You Can't Turn Off*
([English](https://blog.ragnagrok.com/en/2026-10-26-un-filtro-que-no-se-puede-apagar) ·
[español](https://blog.ragnagrok.com/es/2026-10-26-un-filtro-que-no-se-puede-apagar)):
the same four small mistakes, written in Haskell, Rust, Scala 3 and TypeScript, and what each
compiler does with them **out of the box** and **once every door is closed by hand**.

The article's claim in one line: when the code is written by a model, which will take any shortcut
the language allows, *a filter you can't turn off is worth more than a better one you have to
remember to turn on*.

## The result

`check.sh` compiles every file under each setting and checks the verdict. This table is what it
verifies:

| Mistake | Haskell | Rust | Scala 3 | TypeScript |
|---|---|---|---|---|
| **1. A forgotten case** (a third status nobody handles) | bare `ghc`: accepted, **not even a warning**; `-Wall`: warning; locked: rejected | **rejected** | warning; locked: rejected | bare: accepted; `--strict`: rejected |
| **2. An absent value used as if it were there** | **rejected** | **rejected** | **rejected** | bare: accepted; `--strict`: rejected |
| …and its one-word way out | `head`: warning; locked: rejected | `.unwrap()`: accepted; locked: rejected | `.get` or `null`: accepted; locked: rejected | `!`: accepted under `--strict`; locked: rejected |
| **3. An effect inside a calculation** (a `println` in a pricing function) | **rejected**: the type says `IO` | accepted, and no flag closes it | accepted, and no flag closes it | accepted, and no flag closes it |
| …and its way out | `unsafePerformIO`: accepted; locked: rejected | | | |
| **4. A value from outside forced into a type** | `unsafeCoerce`: accepted; locked: rejected | `unsafe { transmute }`: accepted; locked: rejected | `asInstanceOf`: accepted, **throws at run time**; locked: rejected | `as Status`: accepted under `--strict`, **runs on and prints `undefined`**; locked: rejected |

What "locked" means in each language:

| Language | Locked setting | What closes what |
|---|---|---|
| Haskell | `-Wall -Werror -XSafe` | `-Werror` turns the missing case and `head` into errors; Safe Haskell refuses to import `System.IO.Unsafe` and `Unsafe.Coerce` |
| Rust | `#![forbid(unsafe_code)]` (here `-F unsafe_code`) and Clippy with `-D clippy::unwrap_used` | no `unsafe` block anywhere; no `unwrap()` |
| Scala 3 | `-Werror -Yexplicit-nulls` and [WartRemover](https://www.wartremover.org/) with `AsInstanceOf`, `OptionPartial` and `Null` | warnings become errors; `null` is no longer a `Card`; casts and `.get` are forbidden by a compiler plugin |
| TypeScript | `--strict` and typescript-eslint (`no-non-null-assertion`, `consistent-type-assertions: never`, `no-unsafe-*`, `switch-exhaustiveness-check`) | the type checker sees `undefined`; a linter forbids `!`, `as` and `any` |

How to read it, against the article:

- **Rust** rejects mistakes 1 and 2 with no flags at all, and there is no flag that turns those
  checks off. Its ways out are visible: `unsafe` is a keyword one attribute can forbid for the
  whole crate, and `unwrap()` crashes at that line instead of letting a wrong value through. What
  Rust doesn't see is mistake 3: a function's type doesn't say whether it touches the world.
- **Scala 3** only *warns* about the forgotten case, and lets `null`, `asInstanceOf` and `.get`
  through. All of it can be closed, but by hand: two compiler flags and a third-party plugin.
  Nothing in the compiler closes mistake 3.
- **Haskell** is the only one that rejects mistake 3, by type. But bare `ghc` doesn't even warn
  about the forgotten case: that needs `-W` or `-Wall` (which `cabal init` turns on), and turning
  it into an error needs `-Werror`. Its back doors (`unsafePerformIO`, `unsafeCoerce`) are closed
  by Safe Haskell.
- **TypeScript** without `--strict` lets three of the four through without a word. `--strict`
  catches 1 and 2, but `!` and `as` go through it, and the forced conversion doesn't stop at run
  time: it prints `label: undefined` and carries on. A linter closes all of that, if someone
  decides to configure it and keep it configured.

## What's here

| Path | What it is |
|---|---|
| `cases/1-forgotten-case/` | A `Status` with three cases and a `label` function that handles two. |
| `cases/2-absent-value/` | Looking up a card by its code and using its balance: `Naive.*` as if it were always there, `Escape.*` with the one-word way out. |
| `cases/3-hidden-effect/` | A `total` that also prints. `Escape.hs` is Haskell's back door, `unsafePerformIO`. |
| `cases/4-forced-conversion/` | A value from outside forced into a `Status`. |
| `primes/` | The article's one-liners, `take 3 . filter isPrime $ [2..]` and `(2..).filter(\|&n\| is_prime(n)).take(3)`, runnable. |
| `check.sh` | Compiles each file under each setting, checks the verdict and the reason, and runs the escapes worth running. |
| `tsconfig.json`, `eslint.config.mjs` | The locked TypeScript. |

The article's Spanish names became English here: `esPrimo` / `es_primo` → `isPrime` / `is_prime`.

## Running it

With GHC 9.12, Rust 1.94 with Clippy, Scala CLI 1.8 with a JDK, and Node 24 with pnpm:

```sh
pnpm install
./check.sh
```

Each line says the verdict, the language and setting, the file, and the text in the compiler's
output that explains it:

```
ok   accepted  haskell/bare       cases/1-forgotten-case/Naive.hs
ok   warning   haskell/wall       cases/1-forgotten-case/Naive.hs incomplete-patterns
ok   rejected  rust/bare          cases/1-forgotten-case/naive.rs E0004
...
ok   run: node cases/4-forced-conversion/escape.ts -> label: undefined
```

## What this proof of concept doesn't cover

- **Four mistakes are not a benchmark.** They were picked because the article names them (nulls,
  forgotten cases, forced conversions, effects where there shouldn't be any). Other mistakes would
  give other tables.
- **It measures the filter, not the generator.** The article's other half, how well a model writes
  each language, isn't here.
- **Rust's guarantee that matters most isn't in the table.** Memory safety and no data races are
  what Rust guarantees by law, and the table doesn't test them: they would need a fifth case with
  shared mutable state, where the other three languages answer very differently.
- **Mistake 3 in Rust has an architectural fix**, not a flag: a core crate that doesn't depend on
  any I/O library can't do I/O. That's the subject of
  [*First the Filter, Then the Generator*](https://blog.ragnagrok.com/en/2026-10-26-primero-el-filtro-despues-el-generador).
- **Locking is a setting someone has to keep.** In every language here, including Rust's Clippy
  lints, the locked column is opt-in. The difference is how much of the table is already filled in
  before anyone configures anything.
- **Assembly isn't here.** The article uses it as the limit case: no filter at all, unless you can
  prove the result correct. There's nothing to compile-check.

## Further reading

- Hughes (1989), [*Why Functional Programming Matters*](https://doi.org/10.1093/comjnl/32.2.98): generate the infinite and prune it, the primes one-liner.
- Jung, Jourdan, Krebbers and Dreyer (2018), [*RustBelt*](https://doi.org/10.1145/3158154): a proof, for a formal model of a realistic subset of Rust, that its type system guarantees what it promises, even with `unsafe` blocks that keep their contract.
- Qin, Chen, Yu, Song and Zhang (2020), [*Understanding Memory and Thread Safety Practices and Issues in Real-World Rust Programs*](https://doi.org/10.1145/3385412.3386036): all the memory bugs went through `unsafe`.
- Vander Stoep (2025), [*Rust in Android: move fast and fix things*](https://blog.google/security/rust-in-android-move-fast-fix-things/).
