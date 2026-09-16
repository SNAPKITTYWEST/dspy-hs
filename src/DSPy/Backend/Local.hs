module DSPy.Backend.Local
  ( LocalLM(..)
  , constantLM
  , lookupLM
  ) where

import DSPy.Runtime
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as M
import Data.Text (Text)
import qualified Data.Text as T

newtype LocalLM = LocalLM { localHandler :: Text -> Text }

constantLM :: Text -> LocalLM
constantLM t = LocalLM (const t)

lookupLM :: Map Text Text -> LocalLM
lookupLM m = LocalLM (\p -> M.findWithDefault (defaultFor p) p m)
  where
    defaultFor p =
      errorText ("LocalLM: no canned response for prompt: " <> T.take 80 p)

errorText :: Text -> Text
errorText t = "{\"_error\":\"" <> t <> "\"}"

instance LanguageModel LocalLM where
  toLM (LocalLM h) = LM
    { lmId = "local:mock"
    , lmRun = \p -> pure (ModelResponse (h p) [])
    }
