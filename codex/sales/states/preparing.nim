import pkg/chronicles
import pkg/questionable
import pkg/questionable/results
import ../../market
import ../salesagent
import ../statemachine
import ./errorhandling
import ./cancelled
import ./failed
import ./filled
import ./ignored
import ./downloading

type
  SalePreparing* = ref object of ErrorHandlingState

logScope:
    topics = "marketplace sales preparing"

method `$`*(state: SalePreparing): string = "SalePreparing"

method onCancelled*(state: SalePreparing, request: StorageRequest): ?State =
  return some State(SaleCancelled())

method onFailed*(state: SalePreparing, request: StorageRequest): ?State =
  return some State(SaleFailed())

method onSlotFilled*(state: SalePreparing, requestId: RequestId,
                     slotIndex: UInt256): ?State =
  return some State(SaleFilled())

method run*(state: SalePreparing, machine: Machine): Future[?State] {.async.} =
  let agent = SalesAgent(machine)
  let data = agent.data
  let context = agent.context
  let market = context.market
  let reservations = context.reservations

  await agent.retrieveRequest()
  await agent.subscribe()

  without request =? data.request:
    raiseAssert "no sale request"

  let slotId = slotId(data.requestId, data.slotIndex)
  let state = await market.slotState(slotId)
  if state != SlotState.Free:
    return some State(SaleIgnored())

  # TODO: Once implemented, check to ensure the host is allowed to fill the slot,
  # due to the [sliding window mechanism](https://github.com/codex-storage/codex-research/blob/master/design/marketplace.md#dispersal)

  # availability was checked for this slot when it entered the queue, however
  # check to the ensure that there is still availability as they may have
  # changed since being added (other slots may have been processed in that time)
  without availability =? await reservations.find(
      request.ask.slotSize,
      request.ask.duration,
      request.ask.pricePerSlot,
      request.ask.collateral,
      used = false):
    info "no availability found for request, ignoring",
      slotSize = request.ask.slotSize,
      duration = request.ask.duration,
      pricePerSlot = request.ask.pricePerSlot,
      used = false
    return some State(SaleIgnored())

  return some State(SaleDownloading(availability: availability))