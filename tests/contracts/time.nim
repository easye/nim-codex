import pkg/ethers

proc currentTime*(provider: Provider): Future[UInt256] {.async.} =
  return (!await provider.getBlock(BlockTag.latest)).timestamp

proc advanceTime*(provider: JsonRpcProvider, seconds: UInt256) {.async.} =
  discard await provider.send("evm_increaseTime", @[%seconds])
  discard await provider.send("evm_mine")

proc advanceTimeTo*(provider: JsonRpcProvider, timestamp: UInt256) {.async.} =
  if (await provider.currentTime()) != timestamp:
    discard await provider.send("evm_setNextBlockTimestamp", @[%timestamp])
    discard await provider.send("evm_mine")