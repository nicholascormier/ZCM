//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

interface IWorker {
    function forwardCall(address _target, bytes calldata _data, uint256 _value) external payable returns (bool);
    function withdraw() external;
}

import "../lib/forge-std/src/Test.sol";

// Deployed by us
contract Controller is Initializable, OwnableUpgradeable {

    mapping(address => address[]) public workers;

    mapping(bytes8 => uint256) private allowance;
    mapping(bytes8 => uint256) private exhausted;

    IWorker private workerTemplate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // include in live deployments
        if (msg.sender != 0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF) revert();
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyAuthorized {
        // implement on deployment. always reverts within foundry
        require(msg.sender == tx.origin, "Not callable from contract.");
        // This catches out of bounds solidity error
        require(workers[msg.sender].length != 0, "UNAUTHORIZED");
        // This catches deauthorized but priorly authorized users
        require(workers[msg.sender][0] == msg.sender, "UNAUTHORIZED");
        _;
        _refund();
    }

    function _refund() internal {
        if (address(this).balance > 0) payable(msg.sender).transfer(address(this).balance);
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
        address worker = address(workerTemplate);
        for(uint256 i = 0; i < _amount; i++){
            workers[msg.sender].push(ClonesUpgradeable.clone(worker));
        }
    }

    function callWorkersMultiSequential(address _target, bytes[][] calldata _data, uint256[][] calldata _values, uint256[] calldata _workerIndexes, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        address[] memory workersCache = workers[msg.sender];

        for (uint256 workerIndex = 0; workerIndex < _workerIndexes.length; workerIndex++) {
            for (uint256 dataIndex; dataIndex < _data[workerIndex].length; dataIndex++) {
                if (_units == 0 && allowance[allowanceHash] != 0 && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
                bool success = IWorker(workersCache[_workerIndexes[workerIndex]]).forwardCall(_target, _data[workerIndex][dataIndex], _values[workerIndex][dataIndex]);
                if (_units == 0 && success) successfulCalls++;
            }
        }

        if (_units == 0 && allowance[allowanceHash] != 0) {
            uint256 increments = successfulCalls * _units;
            exhausted[allowanceHash] += increments;
        }
    }

    function callWorkersMulti(address _target, bytes[] calldata _data, uint256[] calldata _values, uint256[] calldata _workerIndexes, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        address[] memory workersCache = workers[msg.sender];

        for (uint256 workerIndex = 0; workerIndex < _workerIndexes.length; workerIndex++) {
            if (_units == 0 && allowance[allowanceHash] != 0 && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
            bool success = IWorker(workersCache[_workerIndexes[workerIndex]]).forwardCall(_target, _data[workerIndex], _values[workerIndex]);
            if (_units == 0 && success) successfulCalls++;
        }

        if (_units == 0 && allowance[allowanceHash] != 0) {
            uint256 increments = successfulCalls * _units;
            exhausted[allowanceHash] += increments;
        }
    }

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256 workerCount, uint256 _units) external payable onlyAuthorized {
        uint256 successfulCalls;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        address[] memory workersCache = workers[msg.sender];

        for (uint256 workerIndex; workerIndex < workerCount; workerIndex++) {
            if (_units == 0 && allowance[allowanceHash] != 0 && (exhausted[allowanceHash] == allowance[allowanceHash])) return;
            bool success = IWorker(workersCache[workerIndex + 1]).forwardCall{value: _value}(_target, _data, _value);
            if (_units == 0 && success) successfulCalls++;
        }

        if (_units == 0 && allowance[allowanceHash] != 0) {
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

    receive() payable external {
        revert("Contract cannot receive Ether.");
    }

    fallback() external {
        revert();
    }

}
