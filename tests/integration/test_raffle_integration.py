"""
@dev Raffle integration tests with VRF subs, fund, add consumer
"""

import boa
from script.interactions_vrf import (
    create_subscription,
    fund_subscription,
    add_consumer,
    AMOUNT_TO_FUND,
    moccasin_main,
)


def test_interactions_init_subscription_and_consumer(
    raffle_contract, account_sender, vrf_coordinator
):
    # Arrange
    with boa.env.prank(account_sender.address):
        sub_id = create_subscription(vrf_coordinator)

        # Act
        fund_subscription(sub_id, vrf_coordinator)
        add_consumer(raffle=raffle_contract)

    # Assert
    subscription = vrf_coordinator.getSubscription(sub_id)
    assert subscription[0] == AMOUNT_TO_FUND
    assert subscription[3] == account_sender.address
    assert len(subscription[4]) >= 1


def test_interactions_script_main(account_sender):
    (vrf_coordinator, sub_id) = moccasin_main()

    # Assert
    subscription = vrf_coordinator.getSubscription(sub_id)
    assert subscription[0] == AMOUNT_TO_FUND
    assert subscription[3] == account_sender.address
    assert len(subscription[4]) >= 1
