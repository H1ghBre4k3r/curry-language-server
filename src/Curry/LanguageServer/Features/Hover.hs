{-# LANGUAGE OverloadedStrings #-}
module Curry.LanguageServer.Features.Hover (fetchHover) where

-- Curry Compiler Libraries + Dependencies
import qualified Base.TopEnv as CT

import Control.Monad.Trans (liftIO)
import Control.Monad.Trans.Maybe
import Curry.LanguageServer.IndexStore (ModuleStoreEntry (..))
import Curry.LanguageServer.Logging
import Curry.LanguageServer.Utils.Conversions
import Curry.LanguageServer.Utils.Env
import Curry.LanguageServer.Utils.General
import qualified Language.Haskell.LSP.Types as J

fetchHover :: ModuleStoreEntry -> J.Position -> IO (Maybe J.Hover)
fetchHover entry pos = runMaybeT $ do
    ast <- liftMaybe $ moduleAST entry
    env <- liftMaybe $ compilerEnv entry
    hover <- MaybeT $ runLM (hoverAt pos) env ast
    liftIO $ logs INFO $ "fetchHover: Found " ++ show hover
    return hover

hoverAt :: J.Position -> LM J.Hover
hoverAt pos = do
    (ident, spi) <- findAtPos pos
    valueInfo <- lookupValueInfo ident
    let msg = J.HoverContents $ J.markedUpContent "curry" $ ppToText (CT.origName valueInfo) <> " :: " <> ppToText (valueInfoType valueInfo)
        range = currySpanInfo2Range spi
    return $ J.Hover msg range
