## Nim-Dagger
## Copyright (c) 2022 Status Research & Development GmbH
## Licensed under either of
##  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
##  * MIT license ([LICENSE-MIT](LICENSE-MIT))
## at your option.
## This file may not be copied, modified, or distributed except according to
## those terms.

import std/options

import pkg/leopard
import pkg/stew/results

import ../backend

type
  LeoEncoderBackend* = ref object of EncoderBackend
    encoder*: Option[LeoEncoder]

  LeoDecoderBackend* = ref object of DecoderBackend
    decoder*: Option[LeoDecoder]

method encode*(
  self: LeoEncoderBackend,
  data,
  parity: var openArray[seq[byte]]): Result[void, cstring] =

  var encoder = if self.encoder.isNone:
      self.encoder = (? LeoEncoder.init(
        self.blockSize,
        self.buffers,
        self.parity)).some
      self.encoder.get()
    else:
      self.encoder.get()

  encoder.encode(data, parity)

method decode*(
  self: LeoDecoderBackend,
  data,
  parity,
  recovered: var openArray[seq[byte]]): Result[void, cstring] =

  var decoder = if self.decoder.isNone:
      self.decoder = (? LeoDecoder.init(
        self.blockSize,
        self.buffers,
        self.parity)).some
      self.decoder.get()
    else:
      self.decoder.get()

  decoder.decode(data, parity, recovered)

method release*(self: LeoEncoderBackend) =
  if self.encoder.isSome:
    self.encoder.get().free()

method release*(self: LeoDecoderBackend) =
  if self.decoder.isSome:
    self.decoder.get().free()

func new*(
  T: type LeoEncoderBackend,
  blockSize,
  buffers,
  parity: int): T =
  T(
    blockSize: blockSize,
    buffers: buffers,
    parity: parity)

func new*(
  T: type LeoDecoderBackend,
  blockSize,
  buffers,
  parity: int): T =
  T(
    blockSize: blockSize,
    buffers: buffers,
    parity: parity)