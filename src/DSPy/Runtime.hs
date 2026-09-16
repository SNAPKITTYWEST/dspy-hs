module DSPy.Runtime
  ( Runtime
  , RuntimeEnv(..)
  , ModelResponse(..)
  , LM(..)
  , LanguageModel(..)
  , newRuntimeEnv
  , runRuntime
  , throwDSPy
  , recordEvent
  , callLM
  , modelId
  ) where

import DSPy.Core
import DSPy.Trace
import Control.Monad.Except
import Control.Monad.Reader
import Control.Monad.IO.Class (MonadIO(..))
import Data.IORef
import Data.Text (Text)

data ModelResponse = ModelResponse
  { mrText :: !Text
  , mrMetadata :: ![Event]
  } deriving stock (Show, Eq)

data LM = LM
  { lmId :: !Text
  , lmRun :: Text -> Runtime ModelResponse
  }

class LanguageModel lm where
  toLM :: lm -> LM

data RuntimeEnv = RuntimeEnv
  { envLM :: !LM
  , envTrace :: !(IORef Trace)
  }

newRuntimeEnv :: LM -> IO RuntimeEnv
newRuntimeEnv lm = RuntimeEnv lm <$> newIORef emptyTrace

newtype Runtime a = Runtime
  { unRuntime :: ExceptT DSPyError (ReaderT RuntimeEnv IO) a }
  deriving newtype ( Functor, Applicative, Monad
                   , MonadIO, MonadReader RuntimeEnv, MonadError DSPyError )

runRuntime :: RuntimeEnv -> Runtime a -> IO (Either DSPyError a, Trace)
runRuntime env (Runtime m) = do
  r <- runReaderT (runExceptT m) env
  events <- readIORef (envTrace env)
  pure (r, reverse events)

throwDSPy :: DSPyError -> Runtime a
throwDSPy = throwError

recordEvent :: Event -> Runtime ()
recordEvent e = do
  ref <- asks envTrace
  liftIO (modifyIORef' ref (e :))

callLM :: Text -> Runtime ModelResponse
callLM prompt = do
  lm <- asks envLM
  recordEvent (ModelCalled (lmId lm))
  lmRun lm prompt

modelId :: Runtime Text
modelId = asks (lmId . envLM)
