module Network.WebSockets.Channel where

import Control.Monad.Trans.State.Lazy

data ChannelsState sid cid msg = ChannelsState
  { sessionQueue :: M.Map sid (TQueue msg)
  , channelSessions :: MM.Map sid cid
  }

type Channels m sid cid msg = StateT (ChannelsState sid cid msg) m

registerSession :: MonadIO m => sid (TQueue msg) -> Channels m sid cid msg
registerSession = undefined

unregisterSession :: MonadIO m => sid (TQueue msg) -> Channels m sid cid msg
unregisterSession = undefined

openChannel :: MonadIO m => sid -> cid -> Channels m sid cid msg
openChannel = undefined

closeChannel :: MonadIO m => sid -> cid -> Channels m sid cid msg
closeChannel = undefined

publishMessage :: MonadIO m => sid -> cid -> msg -> Channels m sid cid msg
publishMessage = undefined

publishAndPersistMessage :: MonadIO m => sid -> cid -> msg -> Channels m sid cid msg
publishAndPersistMessage = undefined
