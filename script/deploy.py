from src import raffle
from src.mocks import mock_raffle_pick_winner
from moccasin.boa_tools import VyperContract


def deploy_raffle() -> VyperContract:
    return raffle.deploy()


def deploy_mock_raffle() -> VyperContract:
    return mock_raffle_pick_winner.deploy()


def moccasin_main() -> VyperContract:
    return deploy_raffle()
