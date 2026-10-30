#!/usr/bin/env bash
# Compiles every file in cases/ under each language's settings, and checks the
# verdict (rejected, warning or accepted) and, when there is one, the reason.
# Then runs the two escapes worth running, and the primes one-liners.
set -uo pipefail
cd "$(dirname "$0")"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

scala_version=3.3.6
wartremover=3.4.0
tsc=./node_modules/.bin/tsc
eslint=./node_modules/.bin/eslint

# The settings. "bare" is the compiler with no flags at all; "locked" is the
# compiler plus every flag and tool that closes a way around it.
compile() {
  local lang=$1 mode=$2 file=$3
  case "$lang:$mode" in
    haskell:bare)   ghc -XHaskell2010 -fno-code -fforce-recomp -outputdir "$tmp/ghc" "$file" ;;
    haskell:wall)   ghc -XHaskell2010 -fno-code -fforce-recomp -outputdir "$tmp/ghc" -Wall "$file" ;;
    haskell:locked) ghc -XHaskell2010 -fno-code -fforce-recomp -outputdir "$tmp/ghc" -Wall -Werror -XSafe "$file" ;;

    rust:bare)   rustc --edition 2024 --crate-type lib --emit=metadata --out-dir "$tmp/rust" "$file" ;;
    rust:locked) clippy-driver --edition 2024 --crate-type lib --emit=metadata --out-dir "$tmp/rust" \
                   -F unsafe_code -D clippy::unwrap_used -D clippy::expect_used "$file" ;;

    scala:bare)   scala-cli compile --server=false --workspace "$tmp/scala" -S "$scala_version" \
                    -O -color:never "$file" ;;
    scala:locked) scala-cli compile --server=false --workspace "$tmp/scala" -S "$scala_version" \
                    -O -color:never -O -Werror -O -Yexplicit-nulls \
                    --compiler-plugin "org.wartremover:::wartremover:$wartremover" \
                    -O -P:wartremover:traverser:org.wartremover.warts.AsInstanceOf \
                    -O -P:wartremover:traverser:org.wartremover.warts.OptionPartial \
                    -O -P:wartremover:traverser:org.wartremover.warts.Null "$file" ;;

    typescript:bare)   $tsc --noEmit --target es2022 --lib es2022,dom "$file" ;;
    typescript:strict) $tsc --noEmit --target es2022 --lib es2022,dom --strict "$file" ;;
    typescript:locked) $tsc --noEmit --target es2022 --lib es2022,dom --strict "$file" && $eslint "$file" ;;
  esac
}

language() {
  case "$1" in
    *.hs) echo haskell ;; *.rs) echo rust ;; *.scala) echo scala ;; *.ts) echo typescript ;;
  esac
}

failures=0

# file, setting, expected verdict, and the text that says why.
while read -r file mode expected reason; do
  [[ -z "$file" || "$file" == \#* ]] && continue
  lang=$(language "$file")
  output=$(compile "$lang" "$mode" "$file" 2>&1)
  status=$?
  if (( status != 0 )); then
    verdict=rejected
  elif grep -qiE '(^|[^a-z])warning' <<<"$output"; then
    verdict=warning
  else
    verdict=accepted
  fi
  label=$(printf '%-9s %-18s %s' "$verdict" "$lang/$mode" "$file")
  if [[ "$verdict" != "$expected" ]]; then
    echo "FAIL $label (expected $expected)"; echo "$output" | head -20; failures=1
  elif [[ "$reason" != "-" ]] && ! grep -qF -- "$reason" <<<"$output"; then
    echo "FAIL $label, but not because of: $reason"; echo "$output" | head -20; failures=1
  else
    echo "ok   $label${reason:+ ${reason/#-/}}"
  fi
done <<'EOF'
# 1. A case that nobody handles.
cases/1-forgotten-case/Naive.hs       bare     accepted -
cases/1-forgotten-case/Naive.hs       wall     warning  incomplete-patterns
cases/1-forgotten-case/Naive.hs       locked   rejected Werror=incomplete-patterns
cases/1-forgotten-case/naive.rs       bare     rejected E0004
cases/1-forgotten-case/Naive.scala    bare     warning  match may not be exhaustive
cases/1-forgotten-case/Naive.scala    locked   rejected match may not be exhaustive
cases/1-forgotten-case/naive.ts       bare     accepted -
cases/1-forgotten-case/naive.ts       strict   rejected TS2366
cases/1-forgotten-case/naive.ts       locked   rejected TS2366

# 2. A value that may not be there, used as if it always were.
cases/2-absent-value/Naive.hs         bare     rejected Couldn't match
cases/2-absent-value/Escape.hs        bare     warning  x-partial
cases/2-absent-value/Escape.hs        locked   rejected Werror=x-partial
cases/2-absent-value/naive.rs         bare     rejected E0609
cases/2-absent-value/escape.rs        bare     accepted -
cases/2-absent-value/escape.rs        locked   rejected used `unwrap()`
cases/2-absent-value/Naive.scala      bare     rejected is not a member of Option
cases/2-absent-value/Escape.scala     bare     accepted -
cases/2-absent-value/Escape.scala     locked   rejected OptionPartial
cases/2-absent-value/EscapeNull.scala bare     accepted -
cases/2-absent-value/EscapeNull.scala locked   rejected Null
cases/2-absent-value/naive.ts         bare     accepted -
cases/2-absent-value/naive.ts         strict   rejected TS2532
cases/2-absent-value/escape.ts        strict   accepted -
cases/2-absent-value/escape.ts        locked   rejected no-non-null-assertion

# 3. An effect inside a function that was supposed to only compute.
cases/3-hidden-effect/Naive.hs        bare     rejected IO
cases/3-hidden-effect/Escape.hs       bare     accepted -
cases/3-hidden-effect/Escape.hs       locked   rejected Can't be safely imported
cases/3-hidden-effect/naive.rs        bare     accepted -
cases/3-hidden-effect/naive.rs        locked   accepted -
cases/3-hidden-effect/Naive.scala     bare     accepted -
cases/3-hidden-effect/Naive.scala     locked   accepted -
cases/3-hidden-effect/naive.ts        locked   accepted -

# 4. A value from outside, forced into a type.
cases/4-forced-conversion/Escape.hs    bare    accepted -
cases/4-forced-conversion/Escape.hs    locked  rejected Can't be safely imported
cases/4-forced-conversion/escape.rs    bare    accepted -
cases/4-forced-conversion/escape.rs    locked  rejected unsafe
cases/4-forced-conversion/Escape.scala bare    accepted -
cases/4-forced-conversion/Escape.scala locked  rejected AsInstanceOf
cases/4-forced-conversion/escape.ts    strict  accepted -
cases/4-forced-conversion/escape.ts    locked  rejected consistent-type-assertions
EOF

# Running the forced conversion: Scala stops at the cast, TypeScript carries on.
expect_run() {
  local what=$1 pattern=$2 output
  output=$(eval "$what" 2>&1)
  if grep -qF -- "$pattern" <<<"$output"; then
    echo "ok   run: $what -> $pattern"
  else
    echo "FAIL run: $what, expected: $pattern"; echo "$output" | tail -20; failures=1
  fi
}

expect_run "scala-cli run --server=false --workspace $tmp/scala -S $scala_version cases/4-forced-conversion/Escape.scala" \
  "java.lang.ClassCastException"
expect_run "node cases/4-forced-conversion/escape.ts" "label: undefined"

# The one-liners from the article.
expect_run "runghc primes/Primes.hs" "[2,3,5]"
expect_run "rustc --edition 2024 -o $tmp/primes primes/primes.rs && $tmp/primes" "[2, 3, 5]"

exit $failures
