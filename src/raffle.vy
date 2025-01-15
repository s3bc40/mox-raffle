# pragma version 0.4.0
"""
@license MIT
@author s3b40
@notice
    Raffle contract for the CU intermediate Py & Vyper workshop.
@dev
    We do not allow duplicated address to enter the raffle. But a user
    with different addresses can enter multiple times.
    We have a maximum of 200 players to enter a raffle.
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
event EnteredRaffle:
    player: indexed(address)
    amount: uint256

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
MAX_ARRAY_SIZE: constant(uint256) = 10

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
    """
    @dev Enter raffle external call allowed on if raffle is open.
    """
    assert self.raffle_state == RaffleState.OPEN, "Raffle is computing a winner..."
    self._enter_raffle(msg.sender, msg.value)

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
    success: bool = raw_call(winner, b"", value=winner_gain, revert_on_failure=False)
    assert success, "Sending prize to winner failed"
    log PickedWinnerRaffle(winner, winner_gain)
    



################################################################
#                      INTERNAL FUNCTIONS                      #
################################################################
@internal
def _enter_raffle(sender: address, amount: uint256):
    """
    @dev CEI implemented to avoid any reentrancy risk
    """
    # Check
    assert sender != empty(address), "Sender should not be 0 address"
    assert amount >= ENTRANCE_FEE, "Insufficient entrance fee"
    assert (
        sender not in self.players
    ), "Player already registered to the raffle"

    # Effect
    self.players.append(sender)
    # Avoid full equality to keep the raffle opened
    if len(self.players) >= MAX_PLAYERS:
        self.raffle_state = RaffleState.COMPUTING

    # Interaction
    log EnteredRaffle(sender, amount)


@internal
def fulfillRandomWords(request_id: uint256, randomWords: DynArray[uint256, MAX_ARRAY_SIZE]):
    """ Callback VRF function
    @dev see: https://docs.chain.link/vrf/v2-5/overview/subscription
    """
    pass
    


################################################################
#                        VIEW FUNCTIONS                        #
################################################################
@view
@external
def get_players_count() -> uint256:
    return len(self.players)
    

################################################################
#                      GETTERS & SETTERS                       #
################################################################
@external
def set_raffle_duration(duration: uint256):
    ownable._check_owner()
    assert duration >= DEFAULT_DURATION, "Minimun set for duration not respected"
    self.duration = duration