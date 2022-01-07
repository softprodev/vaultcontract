pragma solidity ^0.4.4;


contract Owned {
    /// Allows only the owner to call a function
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

    function Owned() { owner = msg.sender;}

    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

contract Escapable is Owned {
    address escapeCaller;
    address escapeDestination;

    function Escapable(address _escapeCaller, address _escapeDestination) {
        escapeDestination = _escapeDestination;
        escapeCaller = _escapeCaller;
    }

    modifier onlyOwnerOrEscapeCaller {
        if ((msg.sender != escapeCaller)&&(msg.sender!=owner))
            throw; _;
    }

    /// Last Resort call, to allow for a reaction if something bad happens to
    /// the contract or if some security issue is uncovered.
    function escapeHatch() onlyOwnerOrEscapeCaller {
        if (msg.sender != escapeCaller) throw;
        uint total = this.balance;
        if (!escapeDestination.send(total)) {
            throw;
        }
        EscapeCalled(total);
    }

    function changeEscapeCaller(address _newEscapeCaller) onlyOwnerOrEscapeCaller {
        escapeCaller = _newEscapeCaller;
    }

    event EscapeCalled(uint amount);
}



contract Vault is Escapable {


    struct Payment {
        string description;
        address spender;
        uint earliestPayTime;
        bool cancelled;
        bool paid;
        address recipient;
        uint value;
        uint securityGuardDelay;
    }

    Payment[] public payments;

    address public securityGuard;        // The securityGuard has the power to delay the payments
    uint public absoluteMinTimeLock;
    uint public timeLock;
    uint public maxSecurityGuardDelay;
    mapping (address => bool) public allowedSpenders;

///////
// Modifiers
///////

    modifier onlySecurityGuard { if (msg.sender != securityGuard) throw; _; }

/////////
// Constuctor
/////////

    function Vault(
        address _escapeCaller,
        address _escapeDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay) Escapable(_escapeCaller, _escapeDestination)
    {
        securityGuard = _securityGuard;
        timeLock = _timeLock;
        absoluteMinTimeLock = _absoluteMinTimeLock;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }


    function numberOfPayments() constant returns (uint) {
        return payments.length;
    }

//////
// Receive Ether
//////

    function receiveEther() payable {
        EtherReceived(msg.sender, msg.value);
    }

    function () payable {
        receiveEther();
    }

////////
// Spender Interface
////////

    function authorizePayment(string description, address _recipient, uint _value, uint _paymentDalay) returns(uint) {
        if (!allowedSpenders[msg.sender] ) throw;
        uint idPayment= payments.length;
        payments.length ++;
        Payment payment = payments[idPayment];
        payment.spender = msg.sender;
        payment.earliestPayTime = _paymentDalay >= timeLock ? now + _paymentDalay : now + timeLock;
        payment.recipient = _recipient;
        payment.value = _value;
        payment.description = description;
        PaymentAuthorized(idPayment, payment.recipient, payment.value);
        return idPayment;
    }

    function executePayment(uint _idPayment) {

        if (_idPayment >= payments.length) throw;

        Payment payment = payments[_idPayment];

        if (msg.sender != payment.recipient) throw;
        if (!allowedSpenders[payment.spender]) throw;
        if (now < payment.earliestPayTime) throw;
        if (payment.cancelled) throw;
        if (payment.paid) throw;
        if (this.balance < payment.value) throw;

        payment.paid = true;
        if (! payment.recipient.send(payment.value)) {
            throw;
        }
        PaymentExecuted(_idPayment, payment.recipient, payment.value);
     }

/////////
// SecurityGuard Interface
/////////


    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard {
        if (_idPayment >= payments.length) throw;

        Payment payment = payments[_idPayment];

        if ((payment.securityGuardDelay + _delay > maxSecurityGuardDelay) ||
            (payment.paid) ||
            (payment.cancelled))
            throw;

        payment.securityGuardDelay += _delay;
        payment.earliestPayTime += _delay;
    }

////////
// Owner Interface
///////

    function cancelPayment(uint _idPayment) onlyOwner {
        if (_idPayment >= payments.length) throw;

        Payment payment = payments[_idPayment];

        if (payment.cancelled) throw;
        if (payment.paid) throw;

        payment.cancelled = true;
        PaymentCancelled(_idPayment);
    }

    function authorizeSpender(address _spender, bool _authorize) onlyOwner {
        allowedSpenders[_spender] = _authorize;
        SpenderAuthorization(_spender, _authorize);
    }

    function setSecurityGuard(address _newSecurityGuard) onlyOwner {
        securityGuard = _newSecurityGuard;
    }

    function setTimelock(uint _newTimeLock) onlyOwner {
        if (_newTimeLock < absoluteMinTimeLock) throw;
        timeLock = _newTimeLock;
    }

    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyOwner {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

////////////
// Events
////////////

    event PaymentAuthorized(uint idPayment, address recipient, uint value);
    event PaymentExecuted(uint idPayment, address recipient, uint value);
    event PaymentCancelled(uint idPayment);
    event EtherReceived(address from, uint value);
    event SpenderAuthorization(address spender, bool authorized);

}
