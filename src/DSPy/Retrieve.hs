module DSPy.Retrieve
  ( Document(..)
  , Query(..)
  , Retriever(..)
  , InMemoryIndex
  , buildIndex
  , retrieveFrom
  ) where

import DSPy.Runtime
import Data.List (sortOn)
import Data.Ord (Down(..))
import Data.Text (Text)
import qualified Data.Text as T

newtype Query = Query Text

data Document = Document
  { docId :: !Text
  , docContent :: !Text
  }

class Retriever r where
  retrieve :: r -> Query -> Runtime [Document]

newtype InMemoryIndex = InMemoryIndex [Document]

buildIndex :: [Document] -> InMemoryIndex
buildIndex = InMemoryIndex

retrieveFrom :: InMemoryIndex -> Query -> [Document]
retrieveFrom (InMemoryIndex docs) (Query q) =
  take 5 $ sortOn (Down . score) docs
  where
    toks = T.words . T.toLower
    qtoks = toks q
    score d = length [ () | w <- qtoks, w `elem` toks (docContent d) ]

instance Retriever InMemoryIndex where
  retrieve idx q = pure (retrieveFrom idx q)
