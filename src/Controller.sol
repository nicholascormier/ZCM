//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import "../lib/solady/src/utils/LibClone.sol";
import "./EthSender.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

// Deployed by us
contract Controller is Initializable, OwnableUpgradeable {

    struct TrackingInfo {
        uint128 allowance;
        uint128 exhausted;
    }

    mapping(address => address[]) public workers;

    mapping(bytes8 => TrackingInfo) private tracking;

    address payable private workerTemplate;
    EthSender private ethSender;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // include in live deployments
        //if (msg.sender != 0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF) revert();
       // _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
    }

    modifier onlyAuthorized {
        // implement on deployment. always reverts within foundry
        //require(msg.sender == tx.origin, "Not callable from contract.");
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
        workerTemplate = payable(_worker);
    }

    function setEthSender(address _ethSender) external onlyOwner {
        ethSender = EthSender(_ethSender);
    }

    function _calculateAllowanceHash(address _target, address _caller) internal pure returns (bytes8) {
        // this should be unique per _caller address i think.
        return bytes8(keccak256(abi.encodePacked(_target, _caller)));
    }
 
    function createAllowance(address _target, uint256 _allowance) external onlyAuthorized {
        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);
        tracking[allowanceHash] = TrackingInfo({
            allowance: uint128(_allowance),
            exhausted: 0
        });
    }

    function createWorkers(uint256 _amount) external onlyAuthorized {
        require(workerTemplate != address(0), "No template");
        address worker = address(workerTemplate);
        for(uint96 i; i < _amount; i++){
            LibClone.cloneDeterministic(worker, bytes32(abi.encodePacked(msg.sender, i)));
            //workers[msg.sender].push(LibClone.clone(worker));
        }
    }

    // TODO Add tracking to this function as well
    function callWorkersCustomSequential(address _target, bytes[][] calldata _data, uint256[][] calldata _values, uint256[] calldata _workerIndexes, bool _stopOnFailure) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        // data structure: _data[workerIndex][callIndex]
        // data structure: _values[workerIndex][callIndex]

        unchecked {
            uint256 indexesLength = _workerIndexes.length;
            for (uint256 workerIndex; workerIndex < indexesLength; ++workerIndex) {
                for(uint256 callIndex; callIndex < _data[workerIndex].length; ++callIndex){
                    bytes memory data = abi.encodePacked(_data[workerIndex][callIndex], bytes20(_target));

                    (bool success, ) = workersCache[_workerIndexes[workerIndex]].call{value: _values[workerIndex][callIndex]}(data);

                    if(_stopOnFailure && success == false) break;
                }
            }
        }
    }

    // TODO Add tracking to this function (reminder that tracking here can be unique to each worker because each worker could be doing different transactions)
    function callWorkersCustom(address _target, bytes[] calldata _data, uint256[] calldata _values, uint256[] calldata _workerIndexes, bool _stopOnFailure) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        unchecked {
            uint256 indexesLength = _workerIndexes.length;
            for (uint256 workerIndex; workerIndex < indexesLength; ++workerIndex) {
                bytes memory data = abi.encodePacked(_data[workerIndex], bytes20(_target));

                (bool success, ) = workersCache[_workerIndexes[workerIndex]].call{value: _values[workerIndex]}(data);

                if(_stopOnFailure && success == false) break;
            }
        }
    }

    function callWorkersSequential(address _target, bytes[] calldata _data, uint256[] calldata _values, uint256 workerCount, bool _stopOnFailure) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        unchecked {
            for (uint256 workerIndex; workerIndex < workerCount; ++workerIndex) {
                address worker = workersCache[workerIndex + 1];
                for(uint256 callIndex; callIndex < _data.length; ++callIndex) {
                    bytes memory data = abi.encodePacked(_data[callIndex], bytes20(_target));

                    (bool success, ) = worker.call{value: _values[callIndex]}(data);

                    if(_stopOnFailure && success == false) break;
                }
            }
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

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256 workerCount, uint256 _units, bool _stopOnFailure) external payable onlyAuthorized {
        //address[] storage workersCache = workers[msg.sender];

        bytes memory data = abi.encodePacked(_data, bytes20(_target));

        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        uint128 allowance = tracking[allowanceHash].allowance;
        uint128 minted = tracking[allowanceHash].exhausted;

        address workerLogic = workerTemplate;

        bytes32 initCode = LibClone.initCodeHash(workerLogic);
        
        unchecked {
            // add first everything into the access list
            for (uint96 workerIndex; workerIndex < workerCount; ++workerIndex) {
                if (allowance != 0 && minted >= allowance ) break;
                address worker = LibClone.predictDeterministicAddress(initCode, bytes32(abi.encodePacked(msg.sender, workerIndex)), address(this));
                (bool success, ) = worker.call{value: _value}(data);
                if(success == true) {
                    if(_units != 0) {
                        minted += uint128(_units);
                    }
                }else if(_stopOnFailure){
                    break;
                }
            }
        }

        if (_units != 0 && allowance != 0) {
            tracking[allowanceHash] = TrackingInfo({
                allowance: allowance,
                exhausted: minted
            });
        }
    }

    function callWorkers(address _target, bytes calldata _data, uint256 _value, uint256 workerCount, uint256 _loops, uint256 _units, bool _stopOnFailure) external payable onlyAuthorized {
        address[] storage workersCache = workers[msg.sender];

        bytes memory data = abi.encodePacked(_data, bytes20(_target));

        bytes8 allowanceHash = _calculateAllowanceHash(_target, msg.sender);

        TrackingInfo memory track = tracking[allowanceHash];
        
        unchecked {
            for (uint256 workerIndex; workerIndex < workerCount; ++workerIndex) {
                for(uint256 loopIndex; loopIndex < _loops; ++loopIndex) {
                    if (track.allowance != 0 && track.exhausted >= track.allowance ) break;
                    (bool success, ) = workersCache[workerIndex + 1].call{value: _value}(data);
                    if(success == true) {
                        if(_units != 0) {
                            track.exhausted += uint128(_units);
                        }
                    }else if(_stopOnFailure){
                        break;
                    }
                }
            }
        }

        if (_units != 0 && track.allowance != 0) {
            tracking[allowanceHash] = track;
        }
    }

    function withdrawFromWorkers(uint256[] calldata _workerIndexes, address payable withdrawTo) external onlyAuthorized {
        bytes memory data = abi.encodePacked(abi.encodeWithSignature("empty(address)", withdrawTo), bytes20(address(ethSender)));

        for(uint256 i = 0; i < _workerIndexes.length; i++){
            workers[msg.sender][_workerIndexes[i]].call(data);
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
