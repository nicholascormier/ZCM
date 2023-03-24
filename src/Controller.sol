//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

interface IWorker {
    function forwardCall(address _target, bytes calldata _data, uint256 _value) external payable returns (bool);
    function withdraw() external;
    function setBeacon(address beacon) external;
    function setAdmin(address admin) external;
}

import "./Worker.sol";

// Deployed by us
contract Controller is Initializable, OwnableUpgradeable {

    mapping(address => address[]) public workers;

    mapping(bytes8 => uint256) private allowance;
    mapping(bytes8 => uint256) private exhausted;

    IWorker private workerTemplate;

    // DELETE THIS ON DEPLOYMENT
    address private beacon;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
    }

    // remove modifiers
    modifier onlyAuthorized {
        // This catches out of bounds solidity error
        require(workers[msg.sender].length != 0, "UNAUTHORIZED");
        // This catches deauthorized but priorly authorized users
        require(workers[msg.sender][0] == msg.sender, "UNAUTHORIZED");
        _;
    }
    
    // ## micro optimization
    // --custom errors--
    // error UnauthorizedAccessError();
    // function _isAuthorized(address _caller) internal pure returns (bool) {
    //     return workers[_caller].length != 0 && workers[_caller[0] == _caller];
    // function _authorize(address _caller) internal pure {
    //     if (!_isAuthorized(_caller)) UnauthorizedAccessError();
    // }

    function authorizeCaller(address _user) external onlyOwner {
        if(workers[_user].length == 0){
            workers[_user] = [_user];
        }else{
            workers[_user][0] = _user;
        }
    }

    function deauthorizeCaller(address _user) external onlyOwner {
        // Set the user's first index to zero so if they are re-added their contracts still exist
        require(workers[_user].length > 0, "User does not exist");
        workers[_user][0] = address(0);
    }

    function setWorkerTemplate(address _worker) external onlyOwner {
        workerTemplate = IWorker(_worker);
    }

    function _calculateAllowanceHash(address _target, address _caller) internal pure returns (bytes8) {
        // this should be unique per _caller address i think.
        return bytes8(keccak256(abi.encodePacked(_target, _caller)));
    }
 
    function createAllowance(address _target, uint256 _allowance) external onlyAuthorized {
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);
        allowance[allowanceHash] = _allowance;
    }

    function createWorkers(uint256 _amount) external onlyAuthorized {
        require(workerTemplate != IWorker(address(0)), "No template");

        for(uint256 i = 0; i < _amount; i++){
            // SWAP THESE ON DEPLOYMENT
            //workers[msg.sender].push(ClonesUpgradeable.clone(address(workerTemplate)));

            address workerAddy = ClonesUpgradeable.clone(address(workerTemplate));
            IWorker(workerAddy).setBeacon(beacon);
            workers[msg.sender].push(workerAddy);
        }
    }

    function callWorkersMultiSequential(address _target, bytes[][] calldata _data, uint256[][] calldata _values, uint256[] calldata _workerIndexes, bool _trackMints, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        for (uint256 workerIndex = 0; workerIndex < _workerIndexes.length; workerIndex++) {
            for (uint256 dataIndex; dataIndex < _data[workerIndex].length; dataIndex++) {
                if (_trackMints && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
                bool success = IWorker(workers[msg.sender][_workerIndexes[workerIndex]]).forwardCall(_target, _data[workerIndex][dataIndex], _values[workerIndex][dataIndex]);
                if (_trackMints && success) successfulCalls++;
            }
        }

        if (_trackMints) {
            // require(allowanceToOwner[allowanceHash] == msg.sender, "UNAUTHORIZED ACCESS OF ALLOWANCE HASH.");
            uint256 increments = successfulCalls * _units;
            exhausted[allowanceHash] += increments;
        }
    }

    function callWorkersMulti(address _target, bytes[] calldata _data, uint256[] calldata _values, uint256[] calldata _workerIndexes, bool _trackMints, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        for (uint256 workerIndex = 0; workerIndex < _workerIndexes.length; workerIndex++) {
            if (_trackMints && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
            bool success = IWorker(workers[msg.sender][_workerIndexes[workerIndex]]).forwardCall(_target, _data[workerIndex], _values[workerIndex]);
            if (_trackMints && success) successfulCalls++;
        }

        if (_trackMints) {
            uint256 increments = successfulCalls * _units;
            exhausted[allowanceHash] += increments;
        }
    }

    // function callWorkersBB(address _target, bytes calldata _data, uint256 _value) external payable onlyAuthorized {
    //     for (uint256 i = 1; i < 5; i++) {
    //         IWorker(workers[msg.sender][i]).forwardCall{value: _value}(_target, _data, _value);
    //     }
    // }

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256[] calldata _workers, bool _trackMints, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        for (uint256 i = 0; i < _workers.length; i++) {
            if (_trackMints && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
            bool success = IWorker(workers[msg.sender][_workers[i]]).forwardCall{value: _value}(_target, _data, _value);
            if (_trackMints && success) successfulCalls++;
        }

        if (_trackMints) {
            uint256 increments = successfulCalls * _units;
            exhausted[allowanceHash] += increments;
        }
    }

    // function newCallWorkers(address _target, bytes calldata _data, uint256 _value, uint256[] calldata _workers, bool _trackMints, uint256 _units) external payable onlyAuthorized {

    //     bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

    //     bytes memory workerData = abi.encodeWithSignature("forwardCall(address,bytes,uint256)", _target, _data, _value);

    //     assembly {
    //         let len := mload(_data)
    //         for { let i := 0 } lt(i, len) { i := add(i, 1) } {
    //             if and(_trackMints, eq(exhaused[allowanceHash], allowance[allowanceHash]) { stop() }
    //             let success := mload(0x40)
    //             call(gas(), workers[msg.sender][_workers[i]], _value, _data, )
    //         }
    //     }
    // }

    function withdrawFromWorkers(uint256[] calldata _workerIndexes) external onlyAuthorized {
        for(uint256 i = 0; i < _workerIndexes.length; i++){
            IWorker(workers[msg.sender][_workerIndexes[i]]).withdraw();
        }
    }

    // This is called off-chain
    function getWorkers(address _user) external view returns(address[] memory){
        return workers[_user];
    }

    // DELETE THIS ON DEPLOYMENT
    function setBeacon(address _beacon) external onlyOwner {
        beacon = _beacon;
    }

    function coinbase() external payable onlyAuthorized {
        payable(block.coinbase).transfer(msg.value);
    }

}
