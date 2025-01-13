from src import raffle
from moccasin.boa_tools import VyperContract


def deploy_raffle() -> VyperContract:
    return raffle.deploy()


def moccasin_main() -> VyperContract:
    return deploy_raffle()
