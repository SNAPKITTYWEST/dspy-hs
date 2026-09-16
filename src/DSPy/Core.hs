{-# LANGUAGE StandaloneKindSignatures #-}
module DSPy.Core
  ( DSPyError(..)
  , FieldRole(..)
  , Field(..)
  , FieldCodec(..)
  , Signature(..)
  , signature
  , signatureWithDescriptions
  , sigHashInput
  ) where

import Data.Aeson (Value, object, (.=))
import Data.Aeson.Types (parseEither)
import Data.Kind (Type)
import Data.Proxy (Proxy(..))
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics (Generic)

-- | Structured, typed domain failures. No unchecked exceptions.
data DSPyError
  = InvalidSignature Text
  | InvalidExample Text
  | InvalidPrompt Text
  | ModelFailure Text
  | ParseFailure Text
  | ValidationFailure Text
  | OptimizationFailure Text
  | CompilationFailure Text
  | ToolFailure Text
  deriving stock (Show, Eq, Generic)

data FieldRole = InputField | OutputField
  deriving stock (Show, Eq, Generic)

data Field = Field
  { fieldName :: !Text
  , fieldDescription :: !Text
  , fieldRole :: !FieldRole
  } deriving stock (Show, Eq, Generic)

class FieldCodec a where
  encodeValue :: a -> Value
  decodeValue :: Value -> Either DSPyError a
  fieldNames :: Proxy a -> [Text]

data Signature i o = Signature
  { sigName :: !Text
  , sigInputFields :: ![Field]
  , sigOutputFields :: ![Field]
  } deriving stock (Show, Eq, Generic)

signature :: forall i o. (FieldCodec i, FieldCodec o) => Text -> Signature i o
signature nm =
  let ins = [ Field n "" InputField | n <- fieldNames (Proxy @i) ]
      outs = [ Field n "" OutputField | n <- fieldNames (Proxy @o) ]
  in Signature nm ins outs

signatureWithDescriptions
  :: forall i o. (FieldCodec i, FieldCodec o)
  => Text
  -> [(Text, Text)]
  -> [(Text, Text)]
  -> Signature i o
signatureWithDescriptions nm ins outs =
  Signature
    { sigName = nm
    , sigInputFields = [ mk InputField n d | (n, d) <- ins ]
    , sigOutputFields = [ mk OutputField n d | (n, d) <- outs ]
    }
  where
    mk r n d = Field n d r

sigHashInput :: Signature i o -> Text
sigHashInput s = T.intercalate "|"
  [ sigName s
  , T.intercalate "," (map render (sigInputFields s))
  , T.intercalate "," (map render (sigOutputFields s))
  ]
  where
    render f = fieldName f <> ":" <> fieldRoleText (fieldRole f)
    fieldRoleText InputField = "in"
    fieldRoleText OutputField = "out"
