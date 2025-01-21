# Mox Raffle CU

## Overview
This project was developed as part of the Cyfrin Updraft Intermediate Vyper Workshop using the Moccasin framework. It showcases my personal work and understanding of Vyper smart contract development and testing.

> Note: it is only running on pyevm and anvil. This is not meant to run on a testnet. Maybe coming back to implement this.

### Goals
From https://github.com/Cyfrin/moccasin-full-course-cu

Build a smart contract lottery/raffle yourself, using minimal AI help. You can build a "weak randomness" lotttery, using on-chain randomness (but just know, it's not secure!). Or go the extra mile and use Chainlink VRF 2.5 to build a secure lottery.
1. Have test coverage of over 80% of your lines of code
2. Have a function called `enter_raffle` for people to enter your raffle
3. The raffle should pick 1 winner after X seconds
   1. Have this be a customizable variable
4. The winner should get the sum of all the entrance fees added by the other participants
5. Anyone can call a `pick_winner` or `request_winner` function, that will randomly select the winner.

---

## Technical Details
- **Smart Contract Language:** Vyper
- **Framework:** Moccasin (for testing and deployment)
- **Coding Language:** Python
- **Other Tools:** TOML, git

### File Structure
```
├── lib
│   ├── github
│   └── pypi
├── out
├── script
│   ├── mock
│   └── __pycache__
├── src
│   ├── interfaces
│   └── mocks
└── tests
    ├── integration
    ├── __pycache__
    └── unit
```

---

## Installation and Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/s3bc40/mox-raffle
   cd mox-raffle
   ```

2. Install dependencies:
   ```bash
   # Setup venv python with uv
   uv venv
   uv sync
   source .venv/bin/activate
   # Install dependecies
   mox install
   ```

3. Compile the contracts:
   ```bash
   mox compile
   ```

4. Run the tests:
   ```bash
   mox test
   ```

---

## Testing
This project includes a comprehensive test suite using the Moccasin framework to ensure correctness and security.

### Test Coverage
- Unit amd integration test -> reaching 95% coverage

> TODO later: implement fuzzing test with more experience.

### Run Tests
To execute the test suite, run:
```bash
mox test
```

---

## License
MIT

