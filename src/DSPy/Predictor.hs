module DSPy.Predictor
  ( Predictor(..)
  , mkPredictor
  , predict
  , parseModelJSON
  ) where

import DSPy.Core
import DSPy.Prompt
import DSPy.Runtime
import Data.Aeson (Value, eitherDecodeStrict')
import qualified Data.ByteString.Char8 as BSC
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE

data Predictor i o = Predictor
  { predictorId :: !Text
  , predictorSignature :: !(Signature i o)
  , predictorBuild :: [Value] -> [Value] -> i -> Prompt
  }

mkPredictor
  :: FieldCodec i
  => Text
  -> Signature i o
  -> Predictor i o
mkPredictor pid sig = Predictor pid sig (buildSignaturePrompt sig)

predict :: (FieldCodec i, FieldCodec o) => Predictor i o -> [Value] -> [Value] -> i -> Runtime o
predict Predictor{..} demos demosOut i = do
  let p = predictorBuild demos demosOut i
      txt = compilePrompt p
  recordEvent (PromptCompiled txt)
  resp <- callLM txt
  case parseModelJSON (mrText resp) of
    Left err -> throwDSPy (ParseFailure err)
    Right v -> do
      recordEvent (OutputParsed v)
      case decodeValue v of
        Left e -> throwDSPy e
        Right o -> do
          recordEvent (ValidationPerformed "predictor-decode")
          pure o

parseModelJSON :: Text -> Either Text Value
parseModelJSON t =
  case eitherDecodeStrict' (TE.encodeUtf8 t) of
    Right v -> Right v
    Left _ -> case firstObject t of
      Nothing -> Left ("no JSON object in response: " <> T.take 120 t)
      Just s -> case eitherDecodeStrict' (BSC.pack (T.unpack s)) of
        Right v -> Right v
        Left e -> Left (T.pack e)

firstObject :: Text -> Maybe Text
firstObject t = go (T.unpack t) 0 Nothing
  where
    go [] _ Nothing = Nothing
    go [] _ (Just acc) | balanced acc = Just (T.pack (reverse acc))
                       | otherwise = Nothing
    go (c:cs) depth acc
      | c == '{' = go cs (depth + 1) (Just (c : maybe [] id acc))
      | c == '}' =
          let d' = depth - 1
              acc' = Just (c : maybe [] id acc)
          in if d' == 0 then Just (T.pack (reverse (maybe [] id acc')))
                        else go cs d' acc'
      | depth > 0 = go cs depth (fmap (c :) acc)
      | otherwise = go cs depth acc
    balanced s = count '{' s == count '}' s
    count ch = length . filter (== ch)
