//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

interface IWorker {
    function forwardCall(address _target, bytes calldata _data, uint256 _value) external payable returns (bool);
    function withdraw() external;
    function setBeacon(address beacon) external;
}

import "../lib/forge-std/src/Test.sol";

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

    modifier onlyAuthorized {
        // This catches out of bounds solidity error
        require(workers[msg.sender].length != 0, "UNAUTHORIZED");
        // This catches deauthorized but priorly authorized users
        require(workers[msg.sender][0] == msg.sender, "UNAUTHORIZED");
        _;
    }

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

    function callWorkersBB(address _target, bytes calldata _data, uint256 _value) external payable onlyAuthorized {
        for (uint256 i = 1; i < 5; i++) {
            IWorker(workers[msg.sender][i]).forwardCall{value: _value}(_target, _data, _value);
        }
    }

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256 _startIndex, uint256 _iterations, bool _trackMints, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        for (uint256 iterations = 0; iterations < _iterations; iterations++) {
            if (_trackMints && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
            bool success = IWorker(workers[msg.sender][_iterations + iterations]).forwardCall{value: _value}(_target, _data, _value);
            if (_trackMints && success) successfulCalls++;
        }

        if (_trackMints) {
            uint256 increments = successfulCalls * _units;
            exhausted[allowanceHash] += increments;
        }
    }

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

}
