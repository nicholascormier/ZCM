//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

interface IWorker {
    function forwardCall(address _target, bytes calldata _data, uint256 _value) external payable returns (bool);
    function forwardCalls(address _target, bytes[] calldata _data, uint256[] calldata _values) external payable returns(uint256 successes);
    function withdraw(address payable withdrawTo) external;
}

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

// Deployed by us
contract Controller is Initializable, OwnableUpgradeable {

    mapping(address => address[]) public workers;

    mapping(bytes8 => uint256) private allowance;
    mapping(bytes8 => uint256) private exhausted;

    IWorker private workerTemplate;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // include in live deployments
        //if (msg.sender != 0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF) revert();
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyAuthorized {
        // implement on deployment. always reverts within foundry
        //require(msg.sender == tx.origin, "Not callable from contract.");
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

    function authorizeCallers(address[] calldata _users) external onlyOwner {
        for (uint256 i; i < _users.length; i++) {
            if(workers[_users[i]].length == 0){
                workers[_users[i]] = [_users[i]];
            }else{
                workers[_users[i]][0] = _users[i];
            }
        }
    }

    function deauthorizeCallers(address[] calldata _users) external onlyOwner {
        for (uint256 i; i < _users.length; i++) {
            // Set the user's first index to zero so if they are re-added their contracts still exist
            require(workers[_users[i]].length > 0, "User does not exist");
            workers[_users[i]][0] = address(0);
        }
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

    // TODO Add tracking to this function as well
    function callWorkersCustomSequential(address _target, bytes[][] calldata _data, uint256[][] calldata _values, uint256[] calldata _totalValues, uint256[] calldata _workerIndexes) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        // data structure: _data[workerIndex][callIndex]
        // data structure: _values[workerIndex][callIndex]

        uint256 indexesLength = _workerIndexes.length;
        for (uint256 workerIndex; workerIndex < indexesLength; workerIndex = unchecked_inc(workerIndex)) {
            IWorker(workersCache[_workerIndexes[workerIndex]]).forwardCalls{value: _totalValues[workerIndex]}(_target, _data[workerIndex], _values[workerIndex]);
        }
    }

    // TODO Add tracking to this function (reminder that tracking here can be unique to each worker because each worker could be doing different transactions)
    function callWorkersCustom(address _target, bytes[] calldata _data, uint256[] calldata _values, uint256[] calldata _workerIndexes) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        uint256 indexesLength = _workerIndexes.length;
        for (uint256 workerIndex; workerIndex < indexesLength; workerIndex = unchecked_inc(workerIndex)) {
            IWorker(workersCache[_workerIndexes[workerIndex]]).forwardCall{value: _values[workerIndex]}(_target, _data[workerIndex], _values[workerIndex]);
        }
    }

    // This function is at the stack limit - no more local variables can be added (because of that, costs about 800 more gas per iteration)
    function callWorkersSequential(address _target, bytes[] calldata _data, uint256[] calldata _values, uint256 totalValue, uint256 workerCount) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        for (uint256 workerIndex; workerIndex < workerCount; workerIndex = unchecked_inc(workerIndex)) {
            IWorker(workersCache[workerIndex + 1]).forwardCalls{value: totalValue}(_target, _data, _values);
        }
    }

    // function callWorkersFallback(address _target, bytes calldata _data, uint256 _value, uint256 workerCount, uint256 _units, bool _stopOnFailure) external payable onlyAuthorized {
    //     address[] storage workersCache = workers[msg.sender];
    //     bytes memory sumdata = hex'000000000000000000000000000000000000000000000000000000000000a455';
    //     unchecked {
    //         for (uint256 workerIndex; workerIndex < workerCount; workerIndex++) {
    //             (bool success, ) = address(IWorker(workersCache[workerIndex + 1])).call(abi.encodePacked(bytes4(keccak256("randomBytes")), address(0x0D24e6e50EeC8A1f1DeDa82d94590098A7E664B4), sumdata));
    //         }
    //     }
    // }

    function callWorkersFallback(bytes calldata workerdata, uint256 workercount, uint256 trackunits, bool bypassfailures) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];
        
        unchecked {
            for (uint256 workerIndex; workerIndex < workercount; workerIndex++) {
                (bool success, bytes memory response) = address(IWorker(workersCache[workerIndex + 1])).call(workerdata);
                console.log(success);
                console.logBytes32(bytes32(response));
            }
        }
    }

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256 workerCount, uint256 _units, bool _stopOnFailure) external payable onlyAuthorized {
        uint256 gasLeft = gasleft();
        uint256 totalMintGas;
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        uint256 minted = exhausted[allowanceHash];
        uint256 allowance = allowance[allowanceHash];

        address[] storage workersCache = workers[msg.sender];

        for (uint256 workerIndex; workerIndex < workerCount; workerIndex = unchecked_inc(workerIndex)) {
            if (_units != 0 && allowance != 0 && (minted >= allowance)) break;
            uint256 start = gasleft();
            if(IWorker(workersCache[workerIndex + 1]).forwardCall{value: _value}(_target, _data, _value)){
                totalMintGas += start - gasleft();
                if(_units != 0){
                    unchecked {
                        minted += _units;
                    }
                }
            }else{
                if(_stopOnFailure) break;
            }
        }

        if (_units != 0 && allowance != 0) {
            exhausted[allowanceHash] = minted;
        }

        // I think this reclaims some gas
        minted = 0;
        console.log("gas burned:", gasLeft - gasleft());
        console.log("gas used for minting:", totalMintGas);
    }

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256 workerCount, uint256 _units, uint256 _loops, bool _stopOnFailure) external payable onlyAuthorized {
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        uint256 minted = exhausted[allowanceHash];
        uint256 allowance = allowance[allowanceHash];

        address[] storage workersCache = workers[msg.sender];

        for (uint256 workerIndex; workerIndex < workerCount; workerIndex = unchecked_inc(workerIndex)) {
            for(uint256 currentLoop; currentLoop < _loops; currentLoop = unchecked_inc(currentLoop)){
                if (_units != 0 && allowance != 0 && (minted >= allowance)) break;
                if(IWorker(workersCache[workerIndex + 1]).forwardCall{value: _value}(_target, _data, _value)){
                    if(_units != 0){
                        unchecked {
                            minted += _units;
                        }
                    }
                }else{
                    if(_stopOnFailure) break;
                }
            }
            
        }

        if (_units != 0 && allowance != 0) {
            exhausted[allowanceHash] = minted;
        }

        // I think this reclaims some gas
        minted = 0;
    }

    function withdrawFromWorkers(uint256[] calldata _workerIndexes, address payable withdrawTo) external onlyAuthorized {
        for(uint256 i = 0; i < _workerIndexes.length; i++){
            IWorker(workers[msg.sender][_workerIndexes[i]]).withdraw(withdrawTo);
        }
    }

    function withdrawFromController() external onlyOwner {
        payable(tx.origin).transfer(address(this).balance);
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

    function unchecked_inc(uint i) private returns (uint) {
        unchecked {
            return i + 1;
        }
    }

}
