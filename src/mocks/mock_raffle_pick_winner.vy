# pragma version 0.4.0
"""
@license MIT
@author s3b40
@dev
    Mocking raffle contract pick winner to force an assertion 
    when transaction failed.
"""
################################################################
#                           IMPORTS                            #
################################################################
from snekmate.auth import ownable

initializes: ownable

exports: ownable.owner

################################################################
#                            EVENTS                            #
################################################################
event PickedWinnerRaffle:
    winner: indexed(address)
    prize: uint256


################################################################
#                            FLAGS                             #
################################################################
flag RaffleState:
    COMPUTING
    OPEN


################################################################
#                          CONSTANTS                           #
################################################################
MAX_PLAYERS: public(constant(uint256)) = 200
ENTRANCE_FEE: public(constant(uint256)) = as_wei_value(1, "ether")
# 10 sec duration by default
DEFAULT_DURATION: public(constant(uint256)) = 10


################################################################
#                       STATE VARIABLES                        #
################################################################
players: DynArray[address, MAX_PLAYERS]
raffle_state: public(RaffleState)
duration: public(uint256)
last_timestamp: public(uint256)
last_winner: public(address)



################################################################
#                   CONSTRUCTOR AND FALLBACK                   #
################################################################
@deploy
def __init__():
    ownable.__init__()
    self.raffle_state = RaffleState.OPEN
    self.duration = DEFAULT_DURATION
    self.last_timestamp = block.timestamp
    # @dev For mocking
    self.players.append(empty(address))

@external
@payable
def pick_winner():
    """
    @dev Pick winner external call if duration of raffle respected.
        Sending the sum of all fees to the winner and then reseting
        all players and fees. If no players then we assert the sender.
    """
    # Check
    assert len(self.players) > 0, "No players available for raffle"
    current_timestamp: uint256 = block.timestamp
    assert self.last_timestamp + self.duration <= current_timestamp, "Raffle duration is not reached"

    # Effect
    # @todo RNG with VRF Chainlink
    # Stoping raffle and updating winner prize and address
    self.raffle_state = RaffleState.COMPUTING
    winner: address = self.players[0]
    winner_gain: uint256 = self.balance
    # Reseting the raffle settings
    self.players = []
    self.last_winner = winner
    self.last_timestamp = current_timestamp

    # Interaction
    # @dev Mock should trigger assertion error here for transaction
    success: bool = False
    assert success, "Sending prize to winner failed"
    log PickedWinnerRaffle(winner, winner_gain)
    
