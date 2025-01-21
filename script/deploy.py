"""
@author s3bc40
@notice Dev by myself but improved with the guidance of CU
"""

from eth_utils import to_bytes
from src import raffle
from src.mocks import mock_raffle_pick_winner
from moccasin.boa_tools import VyperContract
from moccasin.config import get_active_network, Network

# @done first step to test our mock before going into TOML
# SUB_ID = 0
# GAS_LANE = "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae"
# ENTRANCE_FEE = 10_000
# CALLBACK_GAS_LIMIT = 500_000
# DURATION = 60


def deploy_raffle(
    vrf_coordinator_contract: VyperContract | None = None,
) -> VyperContract:
    active_network: Network = get_active_network()
    # @dev destructuring a dict
    sub_id, gas_lane, entrance_fee, callback_gas_limit, duration = (
        active_network.extra_data.values()
    )
    vrf_coordinator: VyperContract = (
        vrf_coordinator_contract or active_network.manifest_named("vrf_coordinator_2_5")
    )
    raffle_contract: VyperContract = raffle.deploy(
        duration,
        to_bytes(hexstr=gas_lane),
        sub_id,
        int(entrance_fee),
        callback_gas_limit,
        vrf_coordinator.address,
    )
    print(f"Deployed raffle contract at {raffle_contract.address}")
    return raffle_contract


def deploy_mock_raffle() -> VyperContract:
    return mock_raffle_pick_winner.deploy()


def moccasin_main() -> VyperContract:
    return deploy_raffle()
