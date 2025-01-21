import pytest
from script.deploy import deploy_raffle, deploy_mock_raffle
from moccasin.config import get_active_network, Network
from eth_utils import to_wei
from moccasin.boa_tools import VyperContract
from moccasin.moccasin_account import MoccasinAccount
import boa

STARTING_BALANCE = to_wei("2", "ether")
NUMBER_OF_PLAYERS = 5


@pytest.fixture(scope="session")
def account_sender() -> MoccasinAccount:
    """
    @dev get the default sender from the network to check ownership
    """
    return get_active_network().get_default_account()


@pytest.fixture(scope="function")
def vrf_coordinator() -> VyperContract:
    """
    @dev allows to pass the ownership on the fulfillRandomWords
        and always get the right vrf for the raffle
    """
    active_network: Network = get_active_network()
    return active_network.manifest_named("vrf_coordinator_2_5")


@pytest.fixture(scope="function")
def raffle_contract(vrf_coordinator) -> VyperContract:
    """
    @dev deploying the raffle contract with the right vrf coordinator
    """
    return deploy_raffle(vrf_coordinator)


@pytest.fixture(scope="function")
def player_in_raffle(raffle_contract) -> VyperContract:
    """
    @dev to get the player address registered by default
    """
    player = boa.env.generate_address("player")
    boa.env.set_balance(player, STARTING_BALANCE)
    with boa.env.prank(player):
        raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())
    return player


@pytest.fixture(scope="function")
def mock_raffle_pick_winner() -> VyperContract:
    """
    @dev simple mock without the VRF part to assert on failed transaction
    """
    return deploy_mock_raffle()


@pytest.fixture(scope="function")
def raffle_contract_with_players(raffle_contract) -> VyperContract:
    """
    @dev get the raffle contract with random players inside already
    """
    for i in range(NUMBER_OF_PLAYERS):
        player = boa.env.generate_address(f"player-{i}")
        boa.env.set_balance(player, STARTING_BALANCE)
        with boa.env.prank(player):
            raffle_contract.enter_raffle(value=raffle_contract.ENTRANCE_FEE())

    return raffle_contract
