{-@ measure sigNames :: Signature i o -> [Text] @-}
{-@ invariant {v:Signature i o | not (null (sigNames v))} @-}

{-@ mkSignature :: Text -> { ins:[Field] | not (null ins) }
                 -> { outs:[Field] | not (null outs) }
                 -> Signature i o @-}
