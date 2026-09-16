module DSPy.Trace
  ( Event(..)
  , Trace
  , emptyTrace
  , appendEvent
  ) where

import Data.Aeson (Value)
import Data.Text (Text)
import GHC.Generics (Generic)

data Event
  = ProgramStarted Text
  | PromptCompiled Text
  | ModelCalled Text
  | ToolCalled Text
  | OutputParsed Value
  | ValidationPerformed Text
  | ProgramCompleted
  deriving stock (Show, Eq, Generic)

type Trace = [Event]

emptyTrace :: Trace
emptyTrace = []

appendEvent :: Event -> Trace -> Trace
appendEvent = (:)
