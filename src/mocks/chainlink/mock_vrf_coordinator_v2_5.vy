# pragma version 0.4.0
"""
@license MIT
@author s3bc40
@notice
    Vyper mock version of the VRFCoordinatorV2_5Mock.sol from
    https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol
"""
################################################################
#                           IMPORTS                            #
################################################################
from snekmate.auth import ownable

initializes: ownable


################################################################
#                    CONSTANTS & IMMUTABLES                    #
################################################################
BASE_FEE: public(immutable(uint96))
GAS_PRICE: public(immutable(uint96))
WEI_PER_UNIT_LINK: public(immutable(int256))
MAX_CONSUMER_ARRAY_SIZE: public(constant(uint256)) = 10
MAX_WORD_SIZE: public(constant(uint32)) = 10


################################################################
#                            ERRORS                            #
################################################################
INVALID_REQUEST: constant(String[25]) = "InvalidRequest"
INVALID_RANDOM_WORDS: constant(String[25]) = "InvalidRandomWords"
INVALID_EXTRA_ARGS_TAG: constant(String[25]) = "InvalidExtraArgsTag"
NOT_IMPLEMENTED: constant(String[25]) = "NotImplemented"
INVALID_CONSUMER: constant(String[25]) = "InvalidConsumer"
INVALID_SUBSCRIPTION: constant(String[25]) = "InvalidSubscription"
MUST_BE_SUB_OWNER: constant(String[25]) = "MustBeSubOwner"
TOO_MANY_CONSUMERS: constant(String[25]) = "TooManyConsumers"


################################################################
#                            EVENTS                            #
################################################################
event RandomWordsRequested:
    keyHash: indexed(bytes32)
    requestId: uint256
    preSeed: uint256
    subId: indexed(uint256)
    minimumRequestConfirmations: uint16
    callbackGasLimit: uint32
    numWords: uint32
    extraArgs: Bytes[200]
    sender: indexed(address)


event RandomWordsFulfilled:
    requestId: indexed(uint256)
    outputSeed: uint256
    subId: indexed(uint256)
    payment: uint96
    nativePayment: bool
    success: bool
    onlyPremium: bool


event ConfigSet: pass


event SubscriptionFunded:
    subId: indexed(uint256)
    oldBalance: uint96
    newBalance: uint96


event SubscriptionCreated:
    sub_id: indexed(uint256)
    owner: address


################################################################
#                            STRUCT                            #
################################################################
# @dev we won't be using request list since we are mocking
# and we want simplicity
# struct Request:
#     sub_id: uint256
#     callback_gas_limit: uint32
#     num_words: uint32
#     extra_args: Bytes[200]

# @dev from cyfrin mox repo: import struct to mock other parts needed
struct Subscription:
    balance: uint96
    native_balance: uint96
    req_count: uint64


struct SubscriptionConfig:
    owner: address
    requested_owner: address
    consumers: DynArray[address, MAX_CONSUMER_ARRAY_SIZE]


struct Config:
    minimum_request_confirmations: uint16
    max_gas_limit: uint32
    reentrancy_lock: bool
    staleness_seconds: uint32
    gas_after_payment_calculation: uint32
    fulfillment_flat_fee_native_ppm: uint32
    fulfillment_flat_fee_link_discount_ppm: uint32
    native_premium_percentage: uint8
    link_premium_percentage: uint8


struct ConsumerConfig:
    active: bool
    nonce: uint64
    pending_req_count: uint64


################################################################
#                       STATE VARIABLES                        #
################################################################
# @ not needed for mock since we will stay simple
# current_sub_id: uint64
# next_request_id: uint256
# next_pre_seed: uint256

config: public(Config)


# requests: HashMap[uint256, Request]
# @dev from cyfrin mox repo: import mappings to mock other parts needed
subscriptions: HashMap[uint256, Subscription]
subscription_config: HashMap[uint256, SubscriptionConfig]
consumers: HashMap[address, HashMap[uint256, ConsumerConfig]]

################################################################
#                    CONSTRUCTOR & FALLBACK                    #
################################################################
@deploy
def __init__(base_fee: uint96, gas_price: uint96, wei_per_unit_link: int256):
    ownable.__init__()
    BASE_FEE = base_fee
    GAS_PRICE = gas_price
    WEI_PER_UNIT_LINK = wei_per_unit_link

    # self.next_request_id = 1
    # self.next_pre_seed = 100
    self._set_config()


################################################################
#                      EXTERNAL FUNCTIONS                      #
################################################################
@external
def set_config():
    ownable._check_owner()
    self._set_config()


@nonreentrant
@external
def fulfillRandomWords(request_id: uint256, consumer: address):
    words: DynArray[uint256, MAX_WORD_SIZE] = []
    self.fulfillRandomWordsWithOverride(request_id, consumer, words)


@external
def requestRandomWords(
    key_hash: bytes32,
    sub_id: uint256,
    minimum_request_confirmations: uint16,
    callback_gas_limit: uint32,
    num_words: uint32,
) -> uint256:
    """
    @dev We remove all notion of request, seed for
        mock requestRandomWords. It allows to make a simple function
    @dev see: https://github.com/smartcontractkit/chainlink/blob/912d6bc1c70f0b89ba0d437782e05fbacf335109/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol#L196-L226
    """
    log RandomWordsRequested(
        key_hash,
        0,
        0,
        sub_id,
        minimum_request_confirmations,
        callback_gas_limit,
        num_words,
        b"",
        msg.sender,
    )
    return 0


@external
def fundSubscription(sub_id: uint256, amount: uint96):
    assert self.subscription_config[sub_id].owner != empty(
        address
    ), INVALID_SUBSCRIPTION

    old_balance: uint96 = self.subscriptions[sub_id].balance
    self.subscriptions[sub_id].balance += amount
    log SubscriptionFunded(sub_id, old_balance, old_balance + amount)


@nonreentrant
@external
def createSubscription() -> uint256:
    """
    @dev We won't implement the sub id generation with encryption.
        We'll just keep returning 1
    """
    consumers: DynArray[address, MAX_CONSUMER_ARRAY_SIZE] = []
    self.subscriptions[1] = Subscription(
        balance=0, native_balance=0, req_count=0
    )
    self.subscription_config[1] = SubscriptionConfig(
        owner=msg.sender, requested_owner=msg.sender, consumers=consumers
    )

    log SubscriptionCreated(1, msg.sender)
    return 1


@nonreentrant
@external
def addConsumer(sub_id: uint256, consumer: address):
    self.only_sub_owner(sub_id)
    consumer_config: ConsumerConfig = self.consumers[consumer][sub_id]
    if consumer_config.active:
        return

    consumers: DynArray[
        address, MAX_CONSUMER_ARRAY_SIZE
    ] = self.subscription_config[sub_id].consumers
    assert len(consumers) < MAX_CONSUMER_ARRAY_SIZE, TOO_MANY_CONSUMERS

    consumer_config.active = True
    consumers.append(consumer)


################################################################
#                      INTERNAL FUNCTIONS                      #
################################################################
@internal
def _set_config():
    self.config = Config(
        minimum_request_confirmations=0,
        max_gas_limit=0,
        reentrancy_lock=False,
        staleness_seconds=0,
        gas_after_payment_calculation=0,
        fulfillment_flat_fee_native_ppm=0,
        fulfillment_flat_fee_link_discount_ppm=0,
        native_premium_percentage=0,
        link_premium_percentage=0,
    )
    log ConfigSet()


@internal
def only_valid_consumer(sub_id: uint256, consumer: address):
    assert self.consumer_is_added(sub_id, consumer), INVALID_CONSUMER


@internal
def fulfillRandomWordsWithOverride(
    request_id: uint256,
    consumer: address,
    words: DynArray[uint256, MAX_WORD_SIZE],
):
    """
    @notice Returns an array of numbers to the consumer contract (from raw_call)

    @dev taken from cu repo since there is to much complexity to make the mock out of it
    'In this mock contract, we ignore the requestId and consumer'
    @dev https://github.com/Cyfrin/mox-raffle-cu/blob/e41e3216137ff86c1f663a6730c52dd38586ec12/src/mocks/vrf_coordinator_v2.vy

    @param request_id (uint256) The request Id number
    @param consumer (address) The consumer address to
    @param words (DynArray[uint256, MAX_ARRAY_SIZE]) user-provided random words
    """

    if len(words) == 0:
        words = []
        for i: uint32 in range(MAX_WORD_SIZE):
            words[i] = convert(keccak256(abi_encode(request_id, i)), uint256)
    elif convert(len(words), uint32) != MAX_WORD_SIZE:
        raise INVALID_RANDOM_WORDS

    callReq: Bytes[3236] = abi_encode(
        request_id,
        words,
        method_id=method_id("fulfillRandomWords(uint256,uint256[])"),
    )

    self.config.reentrancy_lock = True
    success: bool = False
    response: Bytes[32] = b""
    success, response = raw_call(
        consumer, callReq, max_outsize=32, revert_on_failure=False
    )
    self.config.reentrancy_lock = False

    log RandomWordsFulfilled(
        request_id, request_id, request_id, 0, True, success, False
    )


@pure
@internal
def _requireValidSubscription(sub_owner: address):
    assert sub_owner != empty(address), INVALID_SUBSCRIPTION


################################################################
#                        VIEW FUNCTIONS                        #
################################################################
@view
@internal
def consumer_is_added(sub_id: uint256, consumer: address) -> bool:
    return self.consumers[consumer][sub_id].active


@view
@internal
def only_sub_owner(sub_id: uint256):
    sub_owner: address = self.subscription_config[sub_id].owner
    self._requireValidSubscription(sub_owner)
    assert msg.sender == sub_owner, MUST_BE_SUB_OWNER


@view
@external
def getSubcription(
    sub_id: uint256,
) -> (
    uint96, uint96, uint64, address, DynArray[address, MAX_CONSUMER_ARRAY_SIZE]
):
    sub_owner: address = self.subscription_config[sub_id].owner
    self._requireValidSubscription(sub_owner)
    return (
        self.subscriptions[sub_id].balance,
        self.subscriptions[sub_id].native_balance,
        self.subscriptions[sub_id].req_count,
        sub_owner,
        self.subscription_config[sub_id].consumers,
    )
