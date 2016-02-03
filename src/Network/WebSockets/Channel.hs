{-# LANGUAGE RecordWildCards #-}

module Network.WebSockets.Channel where

import           Control.Concurrent.STM
import           Control.Monad.Extra

import qualified ListT                  as L
import           Data.Hashable

import qualified STMContainers.Map      as M
import qualified STMContainers.Multimap as MM

data Queue a = Queue { unQueue :: (TQueue a), unCnt :: Int }

instance Hashable (Queue a) where
  hashWithSalt salt (Queue _ cnt) = hashWithSalt salt cnt
  hash (Queue _ cnt) = hash cnt

instance Eq (Queue a) where
  Queue _ cnt == Queue _ cnt' = cnt == cnt'

data ChannelsState sid cid msg = ChannelsState
  { sessionQueue :: M.Map sid (Queue msg)
  , channelQueues :: MM.Multimap cid (Queue msg)

  , queueCount :: TVar Int
  }

emptyState :: STM (ChannelsState sid cid msg)
emptyState = do
  sessionQueue <- M.new
  channelQueues <- MM.new
  queueCount <- newTVar 0

  return ChannelsState {..}

mkQueue :: ChannelsState sid cid msg -> TQueue a -> STM (Queue a)
mkQueue state queue = do
  cnt <- readTVar (queueCount state)
  modifyTVar (queueCount state) (+1)
  return $ Queue queue cnt

registerSession :: (Eq sid, Hashable sid) => ChannelsState sid cid msg -> sid -> (TQueue msg) -> STM ()
registerSession state sid queue = do
  queue' <- mkQueue state queue
  do M.insert queue' sid (sessionQueue state)

unregisterSession :: (Eq sid, Hashable sid) => ChannelsState sid cid msg -> sid -> STM ()
unregisterSession state sid = M.delete sid (sessionQueue state)

joinChannel :: (Eq sid, Hashable sid, Hashable cid, Eq cid) => ChannelsState sid cid msg -> sid -> cid -> STM ()
joinChannel state sid cid =
  whenJustM (M.lookup sid (sessionQueue state))
    $ \queue -> MM.insert queue cid (channelQueues state)

leaveChannel :: (Eq sid, Hashable sid, Hashable cid, Eq cid) => ChannelsState sid cid msg -> sid -> cid -> STM ()
leaveChannel state sid cid =
  whenJustM (M.lookup sid (sessionQueue state))
    $ \queue -> MM.delete queue cid (channelQueues state)

broadcastMessage :: (Hashable cid, Eq cid) => ChannelsState sid cid msg -> sid -> cid -> msg -> STM ()
broadcastMessage state sid cid msg = do
  L.traverse_ (flip writeTQueue msg . unQueue) $ MM.streamByKey cid (channelQueues state)

{-
broadcastAndPersistMessage :: MonadIO m => sid -> cid -> msg -> Channels m sid cid msg
broadcastAndPersistMessage = undefined
-}
