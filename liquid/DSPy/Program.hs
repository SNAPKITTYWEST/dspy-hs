{-@ measure progDemoCount :: Program i o -> Int @-}

{-@ invariant {v:Program i o | progDemoCount v >= 0} @-}

{-@ withDemos :: { ds:[Demo] | len ds <= 100 }
              -> Program i o -> Program i o @-}

{-@ assume nonEmptyDataset :: Dataset i o -> Bool @-}

{-@ compile :: Optimizer opt
            => { d:Dataset i o | nonEmptyDataset d }
            -> Program i o
            -> Metric i o
            -> Runtime (CompiledProgram i o, CompilationMetadata) @-}
