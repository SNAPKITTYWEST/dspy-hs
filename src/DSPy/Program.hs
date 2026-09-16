module DSPy.Program
  ( Program(..)
  , ProgramIR(..)
  , Demo(..)
  , mkDemo
  , runProgram
  , andThen
  , withDemos
  ) where

import DSPy.Core
import DSPy.Runtime
import Data.Aeson (Value)
import Data.Text (Text)

data Demo = Demo
  { demoInput :: !Value
  , demoOutput :: !Value
  } deriving stock (Show, Eq)

mkDemo :: (FieldCodec i, FieldCodec o) => i -> o -> Demo
mkDemo i o = Demo (encodeValue i) (encodeValue o)

data ProgramIR
  = PredictNode !Text
  | CoTNode !Text
  | RetrieveNode !Text
  | ParallelNode ![ProgramIR]
  | SequentialNode ![ProgramIR]
  | ConditionalNode !Text !ProgramIR !ProgramIR
  | OptimizedNode !Value !ProgramIR

data Program i o = Program
  { progName :: !Text
  , progSignature :: !(Signature i o)
  , progIR :: !ProgramIR
  , progDemos :: ![Demo]
  , progRun :: [Demo] -> i -> Runtime o
  }

runProgram :: Program i o -> i -> Runtime o
runProgram p i = progRun p (progDemos p) i

withDemos :: [Demo] -> Program i o -> Program i o
withDemos ds p = p { progDemos = ds }

andThen :: Program a b -> Program b c -> Program a c
andThen p1 p2 = Program
  { progName = progName p1 <> " >>> " <> progName p2
  , progSignature = progSignature p2
  , progIR = SequentialNode [progIR p1, progIR p2]
  , progDemos = []
  , progRun = \demos a -> do
      b <- progRun p1 demos a
      progRun p2 demos b
  }
