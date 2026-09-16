{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import DSPy.Core
import DSPy.Example
import DSPy.Hash
import DSPy.Metric
import DSPy.Module
import DSPy.Optimizer
import DSPy.Program
import DSPy.Runtime
import DSPy.Backend.Local
import Data.Aeson (object, (.=), Value)
import qualified Data.Aeson as A
import Data.Text (Text)
import qualified Data.Text as T
import Data.IORef

newtype Question = Question Text deriving (Show, Eq)
newtype Answer = Answer Text deriving (Show, Eq)

instance FieldCodec Question where
  encodeValue (Question t) = object ["question" .= t]
  decodeValue v = case A.fromJSON v of
    A.Success (Question t) -> Right (Question t)
    _ -> case A.parseMaybe (A.withObject "Question" (A..: "question")) v of
           Just t -> Right (Question t)
           Nothing -> Left (ParseFailure "Question decode failed")
  fieldNames _ = ["question"]

instance FieldCodec Answer where
  encodeValue (Answer t) = object ["answer" .= t]
  decodeValue v = case A.parseMaybe (A.withObject "Answer" (A..: "answer")) v of
    Just t -> Right (Answer t)
    Nothing -> Left (ParseFailure "Answer decode failed")
  fieldNames _ = ["answer"]

arithMock :: Text -> Text
arithMock p
  | "2+2" `T.isInfixOf` p = "{\"reasoning\":\"2+2=4\",\"answer\":\"4\"}"
  | "3+5" `T.isInfixOf` p = "{\"reasoning\":\"3+5=8\",\"answer\":\"8\"}"
  | otherwise = "{\"reasoning\":\"unknown\",\"answer\":\"?\"}"

main :: IO ()
main = do
  let lm = toLM (LocalLM arithMock)
  env <- newRuntimeEnv lm

  let sig = signature @Question @Answer "qa"
      prog = chainOfThought sig

  (r, tr) <- runRuntime env (runProgram prog (Question "What is 2+2?"))
  case r of
    Right (Answer a) | a == "4" -> putStrLn "OK: CoT module produced answer 4"
                     | otherwise -> error ("FAIL: got " <> T.unpack a)
    Left e -> error ("FAIL: " <> show e)
  putStrLn ("Trace events: " <> show (length tr))

  let m = exactMatch
      s = metricRun m (Question "What is 2+2?") (Answer "4") (Answer "4")
  case s of
    Score x | x == 1 -> putStrLn "OK: exactMatch returned 1"
    _ -> error "FAIL: exactMatch"

  let ds = addExample (Example (Question "What is 2+2?") (Answer "4") Nothing A.Null)
         $ addExample (Example (Question "What is 3+5?") (Answer "8") Nothing A.Null)
         $ emptyDataset
      opt = BootstrapFewShot { bfMaxDemos = 2, bfThreshold = 0.9 }
  (r2, _) <- runRuntime env (optimize opt prog ds m)
  case r2 of
    Right p2 -> do
      putStrLn ("OK: optimizer kept " <> show (length (progDemos p2)) <> " demos")
      if length (progDemos p2) >= 1
        then putStrLn "OK: bootstrap demos selected"
        else error "FAIL: no demos selected"
    Left e -> error ("FAIL optimize: " <> show e)

  let h1 = hashText "abc"
      h2 = hashText "abc"
  if h1 == h2 then putStrLn "OK: hash deterministic"
              else error "FAIL: hash not deterministic"

  case score01 1.5 of
    Left _ -> putStrLn "OK: out-of-range score rejected"
    Right _ -> error "FAIL: score01 accepted 1.5"
  case score01 0.5 of
    Right _ -> putStrLn "OK: in-range score accepted"
    Left _ -> error "FAIL: score01 rejected 0.5"

  putStrLn "All tests passed."
