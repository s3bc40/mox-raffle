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
from src.interfaces import VRFCoordinatorV2_5


################################################################
#                           MODULES                            #
################################################################
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
#                    CONSTANTS & IMMUTABLES                    #
################################################################
VRF_COORDINATOR_2_5: public(immutable(VRFCoordinatorV2_5))
KEY_HASH: public(immutable(bytes32))
SUB_ID: public(immutable(uint256))
MIN_REQUEST_CONFIRMATION: public(immutable(uint16))
CALLBACK_GAS_LIMIT: public(immutable(uint32))
DURATION: public(immutable(uint256))

MAX_PLAYERS: public(constant(uint256)) = 200
ENTRANCE_FEE: public(constant(uint256)) = as_wei_value(1, "ether")
# 10 sec duration by default
MAX_ARRAY_SIZE: constant(uint256) = 10
NUM_WORDS: constant(uint32) = 4

################################################################
#                       STATE VARIABLES                        #
################################################################
players: DynArray[address, MAX_PLAYERS]
raffle_state: public(RaffleState)
last_timestamp: public(uint256)
last_winner: public(address)


################################################################
#                   CONSTRUCTOR AND FALLBACK                   #
################################################################
@deploy
def __init__(
    duration: uint256,
    key_hash: bytes32,
    sub_id: uint256,
    min_request_confirmations: uint16,
    callback_gas_limit: uint32,
    vrf_coordinator_v2_5: address,
):
    ownable.__init__()
    self.raffle_state = RaffleState.OPEN
    self.last_timestamp = block.timestamp

    DURATION = duration
    VRF_COORDINATOR_2_5 = VRFCoordinatorV2_5(vrf_coordinator_v2_5)
    KEY_HASH = key_hash
    SUB_ID = sub_id
    MIN_REQUEST_CONFIRMATION = min_request_confirmations
    CALLBACK_GAS_LIMIT = callback_gas_limit


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
    assert (
        self.raffle_state == RaffleState.OPEN
    ), "Raffle is computing a winner..."
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
    assert self._is_raffle_pickable(), "Raffle can not select a winner yet"

    # Effect/Interaction
    # Stoping raffle and updating winner prize and address
    self.raffle_state = RaffleState.COMPUTING
    request_id: uint256 = extcall VRF_COORDINATOR_2_5.requestRandomWords(
        KEY_HASH,
        SUB_ID,
        MIN_REQUEST_CONFIRMATION,
        CALLBACK_GAS_LIMIT,
        NUM_WORDS,
    )


@external
def fulfillRandomWords(
    request_id: uint256, randomWords: DynArray[uint256, MAX_ARRAY_SIZE]
):
    """
    @notice Callback VRF function
    @dev see: https://docs.chain.link/vrf/v2-5/overview/subscription
    """
    # Check
    assert (
        msg.sender == VRF_COORDINATOR_2_5.address
    ), "Only coordinator can fulfill!"

    # Effect
    # Picking winner
    index_winner: uint256 = randomWords[0] % len(self.players)
    winner: address = self.players[index_winner]
    winner_gain: uint256 = self.balance

    # Reseting the raffle settings
    self.players = []
    self.last_winner = winner
    self.last_timestamp = block.timestamp
    self.raffle_state = RaffleState.OPEN

    # Interaction
    success: bool = raw_call(
        winner, b"", value=winner_gain, revert_on_failure=False
    )
    assert success, "Sending prize to winner failed"
    log PickedWinnerRaffle(winner, winner_gain)


@view
@external
def is_winner_pickable() -> bool:
    return self._is_raffle_pickable()


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

    log EnteredRaffle(sender, amount)


@view
@internal
def _is_raffle_pickable() -> bool:
    return (
        self.raffle_state == RaffleState.OPEN
        and self.last_timestamp + DURATION <= block.timestamp
    )


################################################################
#                        VIEW FUNCTIONS                        #
################################################################
@view
@external
def get_players_count() -> uint256:
    return len(self.players)
