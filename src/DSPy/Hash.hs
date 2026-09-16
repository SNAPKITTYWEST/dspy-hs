module DSPy.Hash
  ( Hash(..)
  , hashBytes
  , hashText
  , hashValue
  , hashPair
  , shortHash
  ) where

import Data.Aeson (Value, encode)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base16 as B16
import qualified Data.ByteString.Lazy as BL
import Crypto.Hash.SHA256 (hash)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE

newtype Hash = Hash Text
  deriving stock (Show, Eq, Ord)

hashBytes :: ByteString -> Hash
hashBytes = Hash . TE.decodeUtf8 . B16.encode . hash

hashText :: Text -> Hash
hashText = hashBytes . TE.encodeUtf8

hashValue :: Value -> Hash
hashValue = hashBytes . BL.toStrict . encode

hashPair :: Hash -> Hash -> Hash
hashPair (Hash a) (Hash b) = hashText (a <> b)

shortHash :: Hash -> Text
shortHash (Hash h) = T.take 12 h
