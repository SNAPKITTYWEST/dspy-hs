module DSPy.ReAct
  ( Tool(..)
  , ReAct(..)
  , runReAct
  ) where

import DSPy.Core
import DSPy.Runtime
import Data.Aeson (Value)
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

data Tool i o = Tool
  { toolName :: !Text
  , invoke :: i -> Runtime o
  }

data ReAct = ReAct
  { reactName :: !Text
  , reactTools :: ![Text]
  , reactMaxSteps :: !Int
  }

runReAct :: ReAct -> Text -> Runtime Text
runReAct ReAct{..} goal = do
  recordEvent (ProgramStarted reactName)
  go reactMaxSteps goal
  where
    go 0 _ = do
      recordEvent ProgramCompleted
      pure "max-steps reached"
    go n g = do
      let prompt = "Goal: " <> g <> "\nAvailable tools: " <>
                   T.intercalate ", " reactTools <>
                   "\nRespond with JSON {\"tool\":..., \"args\":...} or {\"final\":...}"
      resp <- callLM prompt
      recordEvent (ToolCalled "<candidate>")
      _ <- pure resp
      go (n - 1) g
