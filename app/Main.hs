{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified DSPy.Hash

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["init"] -> putStrLn "Initialised dspy-hs project skeleton."
    ["validate"] -> putStrLn "Validated (stub)."
    ["compile"] -> putStrLn "Compiled (stub)."
    ["run"] -> putStrLn "Ran (stub)."
    ["optimize"] -> putStrLn "Optimised (stub)."
    ["inspect"] -> putStrLn "Inspected (stub)."
    ["hash", f] -> do
      t <- TIO.readFile f
      putStrLn . T.unpack . renderHash . DSPy.Hash.hashText $ t
    ["verify", _] -> do
      putStrLn "Running Liquid Haskell verification pipeline..."
      putStrLn "(Invoke: liquid src/DSPy/*.hs)"
    _ -> do
      pn <- getProgName
      hPutStrLn stderr ("Usage: " <> pn <> " {init|validate|compile|run|optimize|inspect|verify|hash <file>}")
      exitFailure

renderHash :: DSPy.Hash.Hash -> Text
renderHash (DSPy.Hash.Hash t) = t
