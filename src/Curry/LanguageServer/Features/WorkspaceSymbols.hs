module Curry.LanguageServer.Features.WorkspaceSymbols (fetchWorkspaceSymbols) where

import Control.Monad (join)
import Curry.LanguageServer.IndexStore
import Curry.LanguageServer.Logging
import Curry.LanguageServer.Utils.Conversions
import Data.Maybe (maybeToList)
import qualified Data.Text as T
import qualified Language.Haskell.LSP.Types as J

fetchWorkspaceSymbols :: IndexStore -> T.Text -> IO [J.SymbolInformation]
fetchWorkspaceSymbols store query = do
    logs DEBUG $ "fetchWorkspaceSymbols: Searching " ++ show (storedModuleCount store) ++ " source file(s)..."
    let asts = (maybeToList . moduleAST . snd) =<< storedModules store
    symbols <- filter (matchesQuery query) <$> join <$> (sequence $ workspaceSymbols <$> asts)
    logs INFO $ "fetchWorkspaceSymbols: Found " ++ show (length symbols) ++ " symbol(s)"
    return symbols

matchesQuery :: T.Text -> J.SymbolInformation -> Bool
matchesQuery query (J.SymbolInformation n _ _ _ _) = query `T.isPrefixOf` n
