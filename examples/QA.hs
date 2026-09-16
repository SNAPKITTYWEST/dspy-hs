{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import DSPy.Core
import DSPy.Module
import DSPy.Program
import DSPy.Runtime
import DSPy.Backend.Local
import Data.Aeson (object, (.=))
import qualified Data.Aeson as A
import Data.Text (Text)

newtype Question = Question Text deriving (Show, Eq)
newtype Answer = Answer Text deriving (Show, Eq)

instance FieldCodec Question where
  encodeValue (Question t) = object ["question" .= t]
  decodeValue v = case A.parseMaybe (A.withObject "Question" (A..: "question")) v of
    Just t -> Right (Question t)
    Nothing -> Left (ParseFailure "Question decode failed")
  fieldNames _ = ["question"]

instance FieldCodec Answer where
  encodeValue (Answer t) = object ["answer" .= t]
  decodeValue v = case A.parseMaybe (A.withObject "Answer" (A..: "answer")) v of
    Just t -> Right (Answer t)
    Nothing -> Left (ParseFailure "Answer decode failed")
  fieldNames _ = ["answer"]

qa :: Program Question Answer
qa = chainOfThought (signature @Question @Answer "qa")

main :: IO ()
main = do
  let lm = toLM (LocalLM (\_ ->
              "{\"reasoning\":\"observable steps\",\"answer\":\"Paris\"}"))
  env <- newRuntimeEnv lm
  (r, _) <- runRuntime env (runProgram qa (Question "Capital of France?"))
  print r
