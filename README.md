# vault

This contract is designed to keep Ether inside. The output of the ether can be
triggered only by a closed set of accounts. And the real payment is delayed by
a configurable time. During this deley, a guardian (if defined) can cancel the
payment.

The contract also implements a ScapeHatch mechanism to transfer all the funds to
a secure address in case of an emergency.

### constructing a scapeHatch

This is the constructor for the Vault

    function Vault(
        address _escapeCaller,
        address _escapeDestination,
        address _guardian,
        uint _absoluteMinTimeLock,
        uint _timeLock)

### receive Ether

Ether can be sended directly to the contract or by calling

    receiveEther()

### Managing the list of authorized accounts

The owner can add or remove accounts that can ask for payments. To do so,
the owner can call:

    function authorizeSpender(address _spender, bool _authorize)

### Preparing and executing a payment

Authorized accounts can call

    function authorizePayment(address _recipient, uint _value, bytes _data, uint _minPayTime) returns(uint);

To execute the payment this method must be called after the _minPayTime. Thus method
can be called by any body.

    function executePayment(uint _idPayment)

Any body can query the payments

    function numberOfPayments() constant returns (uint);
    function payment(uint _idPayment)

### Cancelling a payment

The guardian can cancel any payment by calling:

    function cancelPayment(uint _idPayment) onlyGuardianOrOwner

Of course the guardian can be also 0x

The owner can change the guardian by calling

    function changeGuardian(address _newGuardian) onlyOwner

### Change congigurable timelock

The owner can change the minimum time delay to do the payments by calling:

    function changeTimelock(uint _newTimeLock) onlyOwner

There is an harcoded absolute minimum time that even the owner can not change.
To change this absolute minimum, A new deployment of the contract would be needed

### Change the owner of the contract

Owner can transfer ownership of the contract by calling

    function changeOwner(address _newOwner) onlyOwner

### Escape hatch mechanism

A escapeHatch mechanism can be configured so that `escapeCaller` can call
the function `escapeHatch()` and all the funds will be transfered to `escapeDestination`

`escapeCaller`can be changed by the owner or the scapeCaller by calling this function:

    function changeScapeCaller(address _newEscapeCaller) onlyOwnerOrScapeCaller

