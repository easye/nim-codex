import pkg/asynctest
import pkg/questionable
import pkg/chronos
import pkg/codex/contracts/requests
import pkg/codex/sales/states/initialproving
import pkg/codex/sales/states/cancelled
import pkg/codex/sales/states/failed
import pkg/codex/sales/states/filling
import pkg/codex/sales/salesagent
import pkg/codex/sales/salescontext
import ../../examples
import ../../helpers

asyncchecksuite "sales state 'initialproving'":

  let proof = exampleProof()
  let request = StorageRequest.example
  let slotIndex = (request.ask.slots div 2).u256

  var state: SaleInitialProving
  var agent: SalesAgent

  setup:
    let onProve = proc (slot: Slot): Future[seq[byte]] {.async.} =
                            return proof
    let context = SalesContext(onProve: onProve.some)
    agent = newSalesAgent(context,
                          request.id,
                          slotIndex,
                          request.some)
    state = SaleInitialProving.new()

  test "switches to cancelled state when request expires":
    let next = state.onCancelled(request)
    check !next of SaleCancelled

  test "switches to failed state when request fails":
    let next = state.onFailed(request)
    check !next of SaleFailed

  test "switches to filling state when initial proving is complete":
    let next = await state.run(agent)
    check !next of SaleFilling
    check SaleFilling(!next).proof == proof