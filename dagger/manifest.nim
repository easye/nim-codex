## Nim-Dagger
## Copyright (c) 2022 Status Research & Development GmbH
## Licensed under either of
##  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
##  * MIT license ([LICENSE-MIT](LICENSE-MIT))
## at your option.
## This file may not be copied, modified, or distributed except according to
## those terms.

import pkg/libp2p/protobuf/minprotobuf
import pkg/libp2p
import pkg/questionable
import pkg/questionable/results

import ./errors

type
  Manifest* = object
    cid*: ?Cid
    blocks*: seq[Cid]

proc encode*(b: var Manifest): ?!seq[byte] =
  ## Encode the manifest into a ``ManifestCodec``
  ## multicodec container (Dag-pb) for now
  ##

  var pbNode = initProtoBuffer()

  for c in b.blocks:
    var pbLink = initProtoBuffer()
    pbLink.write(1, c.data.buffer) # write Cid links
    pbLink.finish()
    pbNode.write(2, pbLink)

  let cid = !b.cid
  pbNode.write(1, cid.data.buffer) # set the treeHash Cid as the data field
  pbNode.finish()

  return pbNode.buffer.success

proc decode*(_: type Manifest, data: openArray[byte]): ?!Manifest =
  ## Decode a manifest from a data blob
  ##

  var
    pbNode = initProtoBuffer(data)
    cidBuf: seq[byte]
    blocks: seq[Cid]

  if pbNode.getField(1, cidBuf).isErr:
    return failure("Unable to decode Cid from manifest!")

  let cid = ? Cid.init(cidBuf).mapFailure
  var linksBuf: seq[seq[byte]]
  if pbNode.getRepeatedField(2, linksBuf).isOk:
    for pbLinkBuf in linksBuf:
      var
        blocksBuf: seq[seq[byte]]
        blockBuf: seq[byte]
        pbLink = initProtoBuffer(pbLinkBuf)

      if pbLink.getField(1, blockBuf).isOk:
        blocks.add(? Cid.init(blockBuf).mapFailure)

  Manifest(cid: cid.some, blocks: blocks).success