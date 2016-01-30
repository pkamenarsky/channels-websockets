module Network.WebSockets.Channel where

import           Control.Concurrent.STM

import           Data.Hashable

import qualified STMContainers.Map      as M
import qualified STMContainers.Multimap as MM

data ChannelsState sid cid msg = ChannelsState
  { sessionQueue :: M.Map sid (TQueue msg)
  , channelSessions :: MM.Multimap sid cid
  }

registerSession :: (Eq sid, Hashable sid) => ChannelsState sid cid msg -> sid -> (TQueue msg) -> STM ()
registerSession state sid q = M.insert q sid (sessionQueue state)

unregisterSession :: (Eq sid, Hashable sid) => ChannelsState sid cid msg -> sid -> STM ()
unregisterSession state sid = M.delete sid (sessionQueue state)

openChannel :: (Eq sid, Hashable sid, Hashable cid, Eq cid) => ChannelsState sid cid msg -> sid -> cid -> STM ()
openChannel state sid cid = MM.insert cid sid (channelSessions state)

closeChannel :: (Eq sid, Hashable sid, Hashable cid, Eq cid) => ChannelsState sid cid msg -> sid -> cid -> STM ()
closeChannel state sid cid = MM.delete cid sid (channelSessions state)

{-
broadcastMessage :: MonadIO m => sid -> cid -> msg -> Channels m sid cid msg
broadcastMessage = undefined

broadcastAndPersistMessage :: MonadIO m => sid -> cid -> msg -> Channels m sid cid msg
broadcastAndPersistMessage = undefined
-}
