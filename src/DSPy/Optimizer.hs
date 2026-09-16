module DSPy.Optimizer
  ( Optimizer(..)
  , BootstrapFewShot(..)
  , runBootstrapFewShot
  ) where

import DSPy.Core
import DSPy.Example
import DSPy.Metric
import DSPy.Program
import DSPy.Runtime
import Data.Text (Text)

class Optimizer opt where
  optimize :: opt -> Program i o -> Dataset i o -> Metric i o -> Runtime (Program i o)

data BootstrapFewShot = BootstrapFewShot
  { bfMaxDemos :: !Int
  , bfThreshold :: !Double
  }

runBootstrapFewShot :: BootstrapFewShot -> Program i o -> Dataset i o -> Metric i o -> Runtime (Program i o)
runBootstrapFewShot cfg prog ds metric = do
  let exs = unDataset ds
  kept <- go exs []
  let limited = take (bfMaxDemos cfg) kept
  pure (withDemos limited prog)
  where
    go [] acc = pure (reverse acc)
    go (e:es) acc = do
      r <- progRun prog [] (exampleInput e)
      let s = metricRun metric (exampleInput e) (exampleOutput e) r
      case s of
        Score x | x >= bfThreshold cfg ->
          go es (mkDemo (exampleInput e) r : acc)
        _ -> go es acc

instance Optimizer BootstrapFewShot where
  optimize = runBootstrapFewShot
