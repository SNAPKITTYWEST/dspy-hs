module DSPy.Prompt
  ( Prompt(..)
  , compilePrompt
  , buildSignaturePrompt
  , buildCoTPrompt
  ) where

import DSPy.Core
import Data.Aeson (Value, encode, toJSON, object, (.=))
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as BL
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE

data Prompt
  = Literal !Text
  | Instruction !Text
  | FieldRef !Text
  | ValueBlock !Value
  | Compose ![Prompt]

compilePrompt :: Prompt -> Text
compilePrompt = \case
  Literal t -> t
  Instruction t -> t
  FieldRef n -> "$" <> n
  ValueBlock v -> TE.decodeUtf8 (BL.toStrict (encode v))
  Compose ps -> T.intercalate "\n" (map compilePrompt ps)

buildSignaturePrompt
  :: FieldCodec i
  => Signature i o
  -> [Value]
  -> [Value]
  -> i
  -> Prompt
buildSignaturePrompt sig demos demosOut input =
  Compose $
    [ Instruction ("Task: " <> sigName sig)
    , Instruction ("Input fields: " <> T.intercalate ", " (names (sigInputFields sig)))
    , Instruction ("Output fields: " <> T.intercalate ", " (names (sigOutputFields sig)))
    ] ++ demoBlock demos demosOut ++
    [ Literal "Input:"
    , ValueBlock (encodeValue input)
    , Instruction "Respond with a single JSON object containing the output fields."
    ]
  where
    names = map fieldName

buildCoTPrompt
  :: FieldCodec i
  => Signature i o
  -> [Value] -> [Value]
  -> i
  -> Prompt
buildCoTPrompt sig demos demosOut input =
  Compose $
    [ Instruction ("Task: " <> sigName sig)
    , Instruction "Think step by step. Your response MUST be a single JSON object."
    , Instruction "Include a top-level string field \"reasoning\" describing \
                  \observable intermediate steps, followed by the output fields."
    , Instruction ("Output fields: " <> T.intercalate ", " (names (sigOutputFields sig)))
    ] ++ demoBlock demos demosOut ++
    [ Literal "Input:"
    , ValueBlock (encodeValue input)
    , Instruction "JSON response:"
    ]
  where
    names = map fieldName

demoBlock :: [Value] -> [Value] -> [Prompt]
demoBlock ins outs =
  if null ins then []
  else [ Instruction "Examples:"
       , ValueBlock (toJSON (map (\(a, b) -> object ["input" .= a, "output" .= b]) (zip ins outs)))
       ]
