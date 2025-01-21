"""
All interactions possible inside VRFCoordinator

@dev No link token taken into account but in reality we should
    have a mock of link token to fund the VRFCoordinator. Since
    we do not deploy to sepolia or other testnet it is fine
"""

from moccasin.config import get_active_network

AMOUNT_TO_FUND = 10_000


def create_subscription(vrf_coordinator) -> int:
    sub_id: int = vrf_coordinator.createSubscription()
    print(f"Subcription created with sub_id: {sub_id}")
    return sub_id


def fund_subscription(sub_id: int, vrf_coordinator) -> bool:
    vrf_coordinator.fundSubscription(sub_id, AMOUNT_TO_FUND)
    print("Subscription funded")
    return True


def add_consumer(raffle=None):
    active_network = get_active_network()
    if raffle is None:
        raffle = active_network.manifest_named("raffle")
    vrf_coordinator = active_network.manifest_named("vrf_coordinator_2_5")
    sub_id = raffle.SUB_ID()
    vrf_coordinator.addConsumer(sub_id, raffle.address)


def moccasin_main():
    active_network = get_active_network()
    vrf_coordinator = active_network.manifest_named("vrf_coordinator_2_5")
    sub_id = create_subscription(vrf_coordinator)
    fund_subscription(sub_id, vrf_coordinator)
    add_consumer()
    return (vrf_coordinator, sub_id)
