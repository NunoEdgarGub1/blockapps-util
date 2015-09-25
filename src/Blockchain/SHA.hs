{-# LANGUAGE DeriveGeneric, OverloadedStrings #-}

module Blockchain.SHA (
  SHA(..),
  hash
  ) where

import Control.Monad
import qualified Crypto.Hash.SHA3 as C
import qualified Data.Aeson as JSON
import Data.Binary
import qualified Data.ByteString.Base16 as B16
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy as BL
import Numeric

import qualified Blockchain.Colors as CL
import Blockchain.Data.RLP
import Blockchain.ExtWord
import Blockchain.Format
import Blockchain.Util

import GHC.Generics

newtype SHA = SHA Word256 deriving (Show, Eq, Ord, Read, Generic)

instance Format SHA where
  format x | x == hash "" = CL.yellow "<blank>"
  format (SHA x) = CL.yellow $ padZeros 64 $ showHex x ""

instance Binary SHA where
  put (SHA x) = sequence_ $ fmap put $ word256ToBytes $ fromIntegral x
  get = do
    bytes <- replicateM 32 get
    let byteString = B.pack bytes
    return (SHA $ fromInteger $ byteString2Integer byteString)

instance RLPSerializable SHA where
  rlpDecode (RLPString s) | B.length s == 32 = SHA $ decode $ BL.fromStrict s
  rlpDecode (RLPScalar 0) = SHA 0 --special case seems to be allowed, even if length of zeros is wrong
  rlpDecode x = error ("Missing case in rlpDecode for SHA: " ++ show x)
  --rlpEncode (SHA 0) = RLPNumber 0
  rlpEncode (SHA val) = RLPString $ fst $ B16.decode $ BC.pack $ padZeros 64 $ showHex val ""

instance JSON.FromJSON SHA where
instance JSON.ToJSON SHA where


hash::BC.ByteString->SHA
hash = SHA . fromIntegral . byteString2Integer . C.hash 256

