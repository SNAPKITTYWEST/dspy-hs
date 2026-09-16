module DSPy.Module
  ( Module(..)
  , CoT(..)
  , Predict(..)
  , chainOfThought
  , runCoT
  , cotProgram
  ) where

import DSPy.Core
import DSPy.Prompt (buildCoTPrompt, buildSignaturePrompt, compilePrompt)
import DSPy.Runtime
import DSPy.Predictor (parseModelJSON)
import DSPy.Program
import Data.Aeson (Value)
import Data.Text (Text)
import GHC.Generics (Generic)

class Module m i o | m -> i o where
  runModule :: m -> i -> Runtime o

data CoT i o = CoT
  { cotName :: !Text
  , cotSignature :: !(Signature i o)
  } deriving stock (Generic)

chainOfThought :: (FieldCodec i, FieldCodec o) => Signature i o -> Program i o
chainOfThought = cotProgram . CoT "ChainOfThought"

cotProgram :: (FieldCodec i, FieldCodec o) => CoT i o -> Program i o
cotProgram c = Program
  { progName = cotName c
  , progSignature = cotSignature c
  , progIR = CoTNode (sigHashInput (cotSignature c))
  , progDemos = []
  , progRun = runCoT c
  }

runCoT :: forall i o. (FieldCodec i, FieldCodec o)
       => CoT i o -> [Demo] -> i -> Runtime o
runCoT CoT{..} demos i = do
  let (ins, outs) = unzip [ (demoInput d, demoOutput d) | d <- demos ]
      p = buildCoTPrompt cotSignature ins outs i
      txt = compilePrompt p
  recordEvent (ProgramStarted cotName)
  recordEvent (PromptCompiled txt)
  resp <- callLM txt
  case parseModelJSON (mrText resp) of
    Left err -> throwDSPy (ParseFailure err)
    Right v -> do
      recordEvent (OutputParsed v)
      case decodeValue v of
        Left e -> throwDSPy e
        Right o -> do
          recordEvent (ValidationPerformed "cot-decode")
          recordEvent ProgramCompleted
          pure o

instance (FieldCodec i, FieldCodec o) => Module (CoT i o) i o where
  runModule c i = runCoT c [] i

data Predict i o = Predict
  { predictName :: !Text
  , predictSignature :: !(Signature i o)
  }

instance (FieldCodec i, FieldCodec o) => Module (Predict i o) i o where
  runModule Predict{..} i = do
    let p = buildSignaturePrompt predictSignature [] [] i
        txt = compilePrompt p
    recordEvent (ProgramStarted predictName)
    recordEvent (PromptCompiled txt)
    resp <- callLM txt
    case parseModelJSON (mrText resp) of
      Left err -> throwDSPy (ParseFailure err)
      Right v -> do
        recordEvent (OutputParsed v)
        case decodeValue v of
          Left e -> throwDSPy e
          Right o -> pure o
