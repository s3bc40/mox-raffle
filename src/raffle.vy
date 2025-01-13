# pragma version 0.4.0
"""
@license MIT
@author s3b40
@notice
    Raffle contract for the CU intermediate Py & Vyper workshop.
@dev
    We do not allow duplicated address to enter the raffle. But a user
    with different addresses can enter multiple times.
"""
################################################################
#                          CONSTANTS                           #
################################################################
MAX_PLAYERS: constant(uint256) = 200
ENTRANCE_FEE: constant(uint256) = as_wei_value(2, "ether")
OWNER: immutable(address)


################################################################
#                       STATE VARIABLES                        #
################################################################
_players: DynArray[address, MAX_PLAYERS]
_fee_by_players: HashMap[address, uint256]
_pool_prize: uint256

################################################################
#                   CONSTRUCTOR AND FALLBACK                   #
################################################################
@deploy
def __init__():
    OWNER = msg.sender


@external
@payable
def __default__():
    self._enter_raffle(msg.sender, msg.value)


################################################################
#                      EXTERNAL FUNCTIONS                      #
################################################################
@external
@payable
def enter_raffle():
    self._enter_raffle(msg.sender, msg.value)


################################################################
#                      INTERNAL FUNCTIONS                      #
################################################################
@internal
def _enter_raffle(sender: address, amount: uint256):
    # Check
    assert sender != empty(address), "Sender should not be 0 address"
    assert amount >= ENTRANCE_FEE, "Insufficient entrance fee"
    assert (
        sender not in self._players
    ), "You are already registered to the raffle"

    # Effect/Interaction
    self._players.append(sender)
    self._fee_by_players[sender] = amount
    self._pool_prize += amount


################################################################
#                        VIEW FUNCTIONS                        #
################################################################
