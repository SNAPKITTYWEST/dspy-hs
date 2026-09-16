module DSPy.Compiler
  ( CompilationMetadata(..)
  , CompiledProgram(..)
  , compile
  , runCompiled
  , verifyMetadata
  , TypeOfOptimizer(..)
  ) where

import DSPy.Core
import DSPy.Example
import DSPy.Hash
import DSPy.Metric
import DSPy.Optimizer
import DSPy.Program
import DSPy.Runtime
import DSPy.Trace
import Data.Aeson (encode, object, (.=))
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BL
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time.Clock (UTCTime, getCurrentTime)

data CompilationMetadata = CompilationMetadata
  { cmProgramHash :: !Hash
  , cmSignatureHash :: !Hash
  , cmDatasetHash :: !Hash
  , cmMetricId :: !Text
  , cmOptimizerId :: !Text
  , cmModelId :: !Text
  , cmTimestamp :: !UTCTime
  }

newtype CompiledProgram i o = CompiledProgram
  { cpProgram :: Program i o
  }

runCompiled :: CompiledProgram i o -> i -> Runtime o
runCompiled (CompiledProgram p) i = runProgram p i

verifyMetadata :: CompilationMetadata -> Either DSPyError ()
verifyMetadata md
  | T.null (unHash (cmProgramHash md)) = Left (CompilationFailure "empty program hash")
  | T.null (unHash (cmSignatureHash md)) = Left (CompilationFailure "empty signature hash")
  | T.null (cmMetricId md) = Left (CompilationFailure "empty metric id")
  | otherwise = Right ()
  where unHash (Hash t) = t

class TypeOfOptimizer a where
  typeOfOptimizer :: a -> Text

instance TypeOfOptimizer BootstrapFewShot where
  typeOfOptimizer _ = "BootstrapFewShot"

compile
  :: (Optimizer opt, TypeOfOptimizer opt)
  => opt
  -> Program i o
  -> Dataset i o
  -> Metric i o
  -> Runtime (CompiledProgram i o, CompilationMetadata)
compile opt prog ds metric = do
  case unDataset ds of
    [] -> throwDSPy (CompilationFailure "empty dataset")
    _ -> pure ()

  optimized <- optimize opt prog ds metric

  now <- liftIO getCurrentTime
  mid <- modelId
  let sigHash = hashText (sigHashInput (progSignature optimized))
      progHash = hashValue $
        object [ "sig" .= encode (sigHashInput (progSignature optimized))
               , "demos" .= length (progDemos optimized) ]
      dsHash = hashBytes $ BL.toStrict $ encode
                 [ demoInput d | d <- progDemos optimized ]

      md = CompilationMetadata
        { cmProgramHash = progHash
        , cmSignatureHash = sigHash
        , cmDatasetHash = dsHash
        , cmMetricId = metricName metric
        , cmOptimizerId = typeOfOptimizer opt
        , cmModelId = mid
        , cmTimestamp = now
        }

  case verifyMetadata md of
    Left e -> throwDSPy e
    Right _ -> do
      recordEvent (ValidationPerformed "compiled-metadata-verified")
      pure (CompiledProgram optimized, md)
