import pytest
from script.deploy import deploy_raffle
from moccasin.config import get_active_network

@pytest.fixture(scope="function")
def raffle_contract():
    return deploy_raffle()

@pytest.fixture(scope="session")
def account_sender():
    return get_active_network().get_default_account()