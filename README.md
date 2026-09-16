```
██████╗ ███████╗██████╗ ██╗   ██╗    ██╗  ██╗███████╗
██╔══██╗██╔════╝██╔══██╗╚██╗ ██╔╝    ██║  ██║██╔════╝
██████╔╝█████╗  ██████╔╝ ╚████╔╝     ███████║█████╗  
██╔══██╗██╔══╝  ██╔══██╗  ╚██╔╝      ██╔══██║██╔══╝  
██║  ██║███████╗██║  ██║   ██║       ██║  ██║███████╗
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚══════╝

              dspy-hs — Typed, Verified DSPy in Haskell
```

# dspy-hs

Typed, Liquid Haskell–verified reimplementation of **DSPy-style declarative LLM pipelines** in Haskell.

---

## Repository layout

| Path | Contents |
|------|----------|
| `src/DSPy/` | Core library: `Core`, `Hash`, `Trace`, `Prompt`, `Example`, `Metric`, `Runtime`, `Predictor`, `Module`, `Program`, `Optimizer`, `Compiler`, `ReAct`, `Retrieve`, `Backend/Local` |
| `liquid/DSPy/` | Liquid Haskell refinement specs: `Score`, `Probability`, `Signature`, `Program` |
| `app/` | CLI entry point |
| `examples/` | End-to-end QA example with `LocalLM` |
| `test/` | Deterministic test suite (6 tests, no live LM required) |
| `dspy-hs.cabal` | Cabal package and dependency declaration |

---

## Build

```bash
cabal update
cabal build
cabal test
```

GHC 9.x + Cabal 3.x required.

---

## Verification with Liquid Haskell

```bash
liquid src/DSPy/*.hs
liquid liquid/DSPy/*.hs
```

Refinements cover:

- `Score01` — `score01` rejects values outside `[0,1]`
- `Probability` — bounded `[0,1]` type alias
- `Signature` — non-empty input and output field lists
- `Program` — non-negative demo count; non-empty dataset precondition on `compile`

---

## Architecture

```mermaid
flowchart TD
    A["Signature i o\ndeclarative I/O contract"] --> B["Predictor i o\nprompt IR · LM call · parse"]
    B --> C["Program i o\ncomposable · IR-bearing · runnable"]
    C --> D["Optimizer\nBootstrapFewShot — select demos from data"]
    D --> E["Compiler\nhash provenance · CompilationMetadata"]
    E --> F["CompiledProgram i o\ncontent-addressed · verified artifact"]

    style A fill:#0f2744,stroke:#3b82f6,color:#e2e8f0
    style B fill:#0f2744,stroke:#3b82f6,color:#e2e8f0
    style C fill:#0f2744,stroke:#3b82f6,color:#e2e8f0
    style D fill:#0f2744,stroke:#6366f1,color:#e2e8f0
    style E fill:#0f2744,stroke:#6366f1,color:#e2e8f0
    style F fill:#0d3320,stroke:#22c55e,color:#e2e8f0
```

Every layer produces an explicit `Trace` of observable events. No hidden chain-of-thought is consumed; reasoning is asked for as a JSON field and logged as `OutputParsed`.

---

## Runtime execution flow

```mermaid
sequenceDiagram
    participant C as Caller
    participant R as Runtime
    participant LM as LM Boundary
    participant T as Trace

    C->>R: runProgram prog input
    R->>T: ProgramStarted
    R->>R: buildCoTPrompt (Prompt IR)
    R->>T: PromptCompiled
    R->>LM: callLM prompt
    LM-->>R: ModelResponse text
    R->>T: ModelCalled
    R->>R: parseModelJSON → decodeValue
    R->>T: OutputParsed · ValidationPerformed
    R->>T: ProgramCompleted
    R-->>C: Either DSPyError o
```

---

## Optimization + compilation flow

```mermaid
flowchart LR
    DS["Dataset i o"] --> OPT["BootstrapFewShot\nrun program on each example\nkeep score ≥ threshold"]
    MET["Metric i o\nexactMatch · contains · structuredValid"] --> OPT
    OPT --> |selected demos| CP["Program i o\nwith demos attached"]
    CP --> COM["compile\nhash sig · hash demos · hash dataset"]
    COM --> |verifyMetadata| ART["CompiledProgram i o\n+ CompilationMetadata"]

    style DS fill:#0f2744,stroke:#3b82f6,color:#e2e8f0
    style MET fill:#0f2744,stroke:#3b82f6,color:#e2e8f0
    style OPT fill:#2a1f44,stroke:#a855f7,color:#e2e8f0
    style CP fill:#0f2744,stroke:#3b82f6,color:#e2e8f0
    style COM fill:#2a1f44,stroke:#a855f7,color:#e2e8f0
    style ART fill:#0d3320,stroke:#22c55e,color:#e2e8f0
```

---

## Key invariants (made unrepresentable)

- Out-of-range `Score` cannot be constructed (`score01 :: Double -> Either DSPyError Score`)
- `Program i o` applied to wrong type → compile-time error
- `CompiledProgram` requires non-empty dataset and verified metadata
- `LM` boundary is explicit — no ambient IO; all calls go through `callLM` in `Runtime`

---

## Running the example

```bash
cabal run dspy-hs -- run
# or load interactively:
cabal repl
:load examples/QA.hs
main
```

---

## License

Sovereign Leviathan Covenant. See `license`.
