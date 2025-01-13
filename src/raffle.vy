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
#                           IMPORTS                            #
################################################################
from snekmate.auth import ownable

initializes: ownable

exports: ownable.owner


################################################################
#                          CONSTANTS                           #
################################################################
MAX_PLAYERS: public(constant(uint256)) = 200
ENTRANCE_FEE: public(constant(uint256)) = as_wei_value(1, "ether")


################################################################
#                       STATE VARIABLES                        #
################################################################
players: DynArray[address, MAX_PLAYERS]
fee_by_players: public(HashMap[address, uint256])
pool_prize: public(uint256)


################################################################
#                            EVENTS                            #
################################################################
event EnteredRaffle:
    player: indexed(address)
    amount: uint256


################################################################
#                   CONSTRUCTOR AND FALLBACK                   #
################################################################
@deploy
def __init__():
    ownable.__init__()


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
    assert len(self.players) < MAX_PLAYERS, "Players limit reached"
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
        sender not in self.players
    ), "Player already registered to the raffle"

    # Effect
    self.players.append(sender)
    self.fee_by_players[sender] = amount
    self.pool_prize += amount

    # Interaction
    log EnteredRaffle(sender, amount)

################################################################
#                        VIEW FUNCTIONS                        #
################################################################
@view
@external
def get_players_count() -> uint256:
    return len(self.players)
    
