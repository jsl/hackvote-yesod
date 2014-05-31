module Handler.ProjectDetails where

import Import
import qualified Data.Text as T
import qualified Data.Text.Read as TR

postProjectDetailsR :: ProjectId -> Handler Html
postProjectDetailsR projectId = do
    project <- runDB $ get404 projectId
    remainingVotes <- getVotes $ projectHackday project
    if remainingVotes > 0
        then do
            setSession (remainingVotesKey $ projectHackday project) (T.pack $ show $ remainingVotes - 1)
            voteFor projectId
            setMessage "Vote successful!"
            redirect $ HackDayDetailsR $ projectHackday project
        else do
            setMessage "Out of votes!"
            redirect $ HackDayDetailsR $ projectHackday project
    --let maybeVotes = lookupSession $ remainingVotesKey (projectHackday project)
    --in case maybeVotes of
    --    Just voteString -> do
    --                     let votes = read votes :: Int
    --    Nothing -> 
    --error "Not yet implemented: putProjectDetailsR"
readInt :: Text -> Int
readInt text = case TR.decimal text of
                Right (int,_) -> int
                Left _ -> error "Invalid Remaining Votes Key" -- Probably should return Nothing here, and default to 3

-- Gets the remaining votes for the given HackDay
-- If not present in the session, sets it to the default value.
getVotes :: HackDayId -> Handler Int
getVotes hackDayId = do
    maybeVotes <- lookupSession $ remainingVotesKey hackDayId
    liftIO $ print maybeVotes
    let maybeIntVotes = fmap (readInt) maybeVotes
      in case maybeIntVotes of
        Just votes -> return votes
        Nothing -> do
            setSession (remainingVotesKey hackDayId) defaultVotesText
            return defaultVotes

voteFor :: ProjectId -> Handler ()
voteFor projectId = do
    runDB $ updateWhere [ProjectId ==. projectId] [ProjectVotes +=. 1]