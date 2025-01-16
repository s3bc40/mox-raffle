"""
@author s3bc40
@notice Mostly from
    https://github.com/Cyfrin/mox-raffle-cu/blob/e41e3216137ff86c1f663a6730c52dd38586ec12/script/mock_deployer/deploy_vrf_coordinator.py
"""

from moccasin.boa_tools import VyperContract
from eth_utils import to_wei
from src.mocks.chainlink import mock_vrf_coordinator_v2_5

BASE_FEE = to_wei(0.25, "ether")
GAS_PRICE = int(1e9)
WEI_PER_UNIT_LINK = int(4e15)


def deploy_mock_vrf_coordinator() -> VyperContract:
    return mock_vrf_coordinator_v2_5.deploy(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK)


def moccasin_main() -> VyperContract:
    return deploy_mock_vrf_coordinator()
