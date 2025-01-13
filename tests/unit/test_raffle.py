"""
@dev
    Unittests for the Raffle contract
"""

import boa
from eth_utils import to_wei

RANDOM_USER = boa.env.generate_address("random_user")
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"


def test_raffle_deploy(raffle_contract, account_sender):
    assert account_sender.address == raffle_contract.owner()
    assert raffle_contract.get_players_count() == 0


def test_raffle_enter_no_address(raffle_contract):
    with boa.env.prank(ZERO_ADDRESS):
        with boa.reverts("Sender should not be 0 address"):
            raffle_contract.enter_raffle()


def test_raffle_enter_not_enough_fee(raffle_contract):
    boa.env.set_balance(RANDOM_USER, to_wei("2", "ether"))
    with boa.env.prank(RANDOM_USER):
        with boa.reverts("Insufficient entrance fee"):
            raffle_contract.enter_raffle(value=to_wei("0.0001", "ether"))


def test_raffle_enter_no_duplicated_player(raffle_contract):
    boa.env.set_balance(RANDOM_USER, to_wei("2", "ether"))
    with boa.env.prank(RANDOM_USER):
        raffle_contract.enter_raffle(value=to_wei("1", "ether"))
        with boa.reverts("Player already registered to the raffle"):
            raffle_contract.enter_raffle(value=to_wei("1", "ether"))


# @todo to continue
