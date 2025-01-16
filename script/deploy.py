"""
@author s3bc40
@notice Dev by myself but improved with the guidance of CU
"""

from eth_utils import to_bytes
from src import raffle
from src.mocks import mock_raffle_pick_winner
from script.mock.deploy_vrf_coordinator import deploy_mock_vrf_coordinator
from moccasin.boa_tools import VyperContract

# @dev first step to test our mock before going into TOML
SUB_ID = 0
GAS_LANE = "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae"
ENTRANCE_FEE = 10_000
CALLBACK_GAS_LIMIT = 500_000
DURATION = 60


def deploy_raffle(vrf_coordinator_contract: VyperContract | None) -> VyperContract:
    # @dev will be moved to moccasin toml config manifest contract
    vrf_coordinator: VyperContract = (
        vrf_coordinator_contract or deploy_mock_vrf_coordinator()
    )
    raffle_contract: VyperContract = raffle.deploy(
        DURATION,
        to_bytes(hexstr=GAS_LANE),
        SUB_ID,
        int(ENTRANCE_FEE),
        CALLBACK_GAS_LIMIT,
        vrf_coordinator.address,
    )
    print(f"Deployed raffle contract at {raffle_contract.address}")
    return raffle_contract


def deploy_mock_raffle() -> VyperContract:
    return mock_raffle_pick_winner.deploy()


def moccasin_main() -> VyperContract:
    return deploy_raffle()
