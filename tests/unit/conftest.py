import pytest
from script.deploy import deploy_raffle, deploy_mock_raffle
from moccasin.config import get_active_network
from eth_utils import to_wei
from moccasin.boa_tools import VyperContract
from moccasin.moccasin_account import MoccasinAccount
import boa

STARTING_BALANCE = to_wei("2", "ether")
NUMBER_OF_PLAYERS = 5


@pytest.fixture(scope="session")
def account_sender() -> MoccasinAccount:
    return get_active_network().get_default_account()


@pytest.fixture(scope="function")
def raffle_contract() -> VyperContract:
    return deploy_raffle()


@pytest.fixture(scope="function")
def mock_raffle_pick_winner() -> VyperContract:
    return deploy_mock_raffle()


@pytest.fixture(scope="function")
def raffle_contract_with_players(raffle_contract) -> VyperContract:
    for i in range(NUMBER_OF_PLAYERS):
        player = boa.env.generate_address(f"player-{i}")
        boa.env.set_balance(player, STARTING_BALANCE)
        with boa.env.prank(player):
            raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())

    return raffle_contract
