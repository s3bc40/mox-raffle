"""
@dev
    Unittests for the Raffle contract
"""

import boa
from eth_utils import to_wei

RANDOM_USER = boa.env.generate_address("random_user")
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
INSUFFICIENT_FEE = to_wei("0.0001", "ether")
STARTING_BALANCE = to_wei("2", "ether")
INSUFICIENT_DURATION = 1
UPDATED_DURATION = 20


################################################################
#                     DEPLOY AND FALLBACK                      #
################################################################
def test_raffle_deploy(raffle_contract, account_sender):
    assert account_sender.address == raffle_contract.owner()
    assert raffle_contract.get_players_count() == 0


def test_raffle_fallback(raffle_contract_with_players):
    # Arrange
    initital_balance = boa.env.get_balance(raffle_contract_with_players.address)
    initial_players_count = raffle_contract_with_players.get_players_count()
    boa.env.set_balance(RANDOM_USER, STARTING_BALANCE)

    # Act
    raffle_contract_with_players.__default__(
        sender=RANDOM_USER, value=raffle_contract_with_players.ENTRANCE_FEE()
    )

    # Assert
    logs = raffle_contract_with_players.get_logs()
    log_random_player = logs[0].topics[0]

    assert raffle_contract_with_players.get_players_count() > initial_players_count
    assert (
        boa.env.get_balance(raffle_contract_with_players.address)
        == raffle_contract_with_players.ENTRANCE_FEE() + initital_balance
    )
    assert log_random_player == RANDOM_USER


################################################################
#                         ENTER RAFFLE                         #
################################################################
def test_raffle_enter_no_address(raffle_contract):
    with boa.env.prank(ZERO_ADDRESS):
        with boa.reverts("Sender should not be 0 address"):
            raffle_contract.enter_raffle()


def test_raffle_enter_not_enough_fee(raffle_contract):
    boa.env.set_balance(RANDOM_USER, STARTING_BALANCE)
    with boa.env.prank(RANDOM_USER):
        with boa.reverts("Insufficient entrance fee"):
            raffle_contract.enter_raffle(value=INSUFFICIENT_FEE)


def test_raffle_enter_no_duplicated_player(raffle_contract):
    boa.env.set_balance(RANDOM_USER, STARTING_BALANCE)
    with boa.env.prank(RANDOM_USER):
        raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())
        with boa.reverts("Player already registered to the raffle"):
            raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())


def test_raffle_player_enter_raffle(raffle_contract):
    # Arrange
    boa.env.set_balance(RANDOM_USER, STARTING_BALANCE)

    # Act
    with boa.env.prank(RANDOM_USER):
        raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())

    # Assert
    logs = raffle_contract.get_logs()
    log_player = logs[0].topics[0]

    assert raffle_contract.get_players_count() == 1
    assert (
        boa.env.get_balance(raffle_contract.address) == raffle_contract.ENTRANCE_FEE()
    )
    assert log_player == RANDOM_USER


def test_raffle_players_limit_reached(raffle_contract):
    for i in range(raffle_contract.MAX_PLAYERS()):
        player = boa.env.generate_address(f"player-{i}")
        boa.env.set_balance(player, STARTING_BALANCE)
        with boa.env.prank(player):
            raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())

    # @todo check rafflestate is computing
    with boa.reverts("Raffle is computing a winner..."):
        raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())


################################################################
#                         PICK WINNER                          #
################################################################
def test_raffle_pick_winner_duration_not_reached(raffle_contract_with_players):
    # Arrange/Act/Assert
    with boa.reverts("Raffle duration is not reached"):
        raffle_contract_with_players.pick_winner()


def test_raffle_pick_winner_no_players(raffle_contract):
    # Arrange/Act/Assert
    with boa.reverts("No players available for raffle"):
        raffle_contract.pick_winner()


def test_raffle_pick_winner_transaction_failed(mock_raffle_pick_winner):
    # Arrange
    boa.env.time_travel(
        mock_raffle_pick_winner.last_timestamp() + mock_raffle_pick_winner.duration()
    )

    # Act/Assert
    with boa.reverts("Sending prize to winner failed"):
        mock_raffle_pick_winner.pick_winner()


def test_raffle_pick_winner(raffle_contract_with_players):
    # Arrange
    raffle_balance: int = boa.env.get_balance(raffle_contract_with_players.address)
    boa.env.time_travel(
        raffle_contract_with_players.last_timestamp()
        + raffle_contract_with_players.duration()
    )

    # Act
    raffle_contract_with_players.pick_winner()

    # Assert
    logs = raffle_contract_with_players.get_logs()
    log_picked_winner = logs[0].topics[0]

    assert log_picked_winner == raffle_contract_with_players.last_winner()
    assert (
        boa.env.get_balance(raffle_contract_with_players.last_winner())
        >= raffle_balance
    )
    assert raffle_contract_with_players.get_players_count() == 0
    assert boa.env.get_balance(raffle_contract_with_players.address) == 0


################################################################
#                     GETTERS AND SETTERS                      #
################################################################
def test_raffle_set_duration_not_owner(raffle_contract):
    with boa.env.prank(RANDOM_USER):
        with boa.reverts("ownable: caller is not the owner"):
            raffle_contract.set_raffle_duration(UPDATED_DURATION)


def test_raffle_set_duration_too_low(raffle_contract):
    with boa.env.prank(raffle_contract.owner()):
        with boa.reverts("Minimun set for duration not respected"):
            raffle_contract.set_raffle_duration(INSUFICIENT_DURATION)


def test_raffle_get_duration(raffle_contract):
    with boa.env.prank(raffle_contract.owner()):
        raffle_contract.set_raffle_duration(UPDATED_DURATION)
    assert raffle_contract.duration() == UPDATED_DURATION
