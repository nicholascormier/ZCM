import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../src/Controller.sol";
import "../src/ProxyController.sol";
import "../src/Worker.sol";

import "../test/samples/MockNFT.sol";
import "../test/samples/MechaPixels.sol";
import "../test/samples/Nakamiga.sol";
import "../test/samples/Multitest.sol";

contract Setup {
    ProxyAdmin proxyAdmin = ProxyAdmin(0x41c2B7eA05f741a3f781fC64ddd997E169ee86c2);
    Controller controllerLogic = Controller(payable(0xe7e35494C566452E526Ea087ec67a42FddA71fE3));
    TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(0xe5D73bCA1cf0e8bF15D23Dda227DC7946583B1E4));
    Controller controller = Controller(payable(address(proxy)));
    Worker worker = Worker(0x8F14C674624a36500d19C6686A60e30b876acA7e);
}

contract AuthorizeCaller is Script, Setup{

    address[] caller = [0x7Ec2606Ae03E8765cc4e65b4571584ad4bdc2AaF];

    function run() public {
        vm.startBroadcast();
        controller.authorizeCallers(caller);
        vm.stopBroadcast();
    }

}

contract CreateWorkers is Script, Setup {
    
        function run() public {
            vm.startBroadcast();
            controller.createWorkers(250);
            vm.stopBroadcast();
        }
    
}

contract DeployMockNFT is Script, Setup {

    function run() public {
        vm.startBroadcast();
        MockNFT mockNFT = new MockNFT();
        mockNFT.setMintActive(true);
        mockNFT.setMintLimit(1);
        vm.stopBroadcast();

        console.log("Mock NFT:", address(mockNFT));
    }

}

contract CallWorkers is Script, Setup {

    function run() public {
        MockNFT nft = MockNFT(0x8362985873aC1A7E86bcaD2BFfC808526E1717D8);
        vm.startBroadcast();
        nft.setMintLimit(20);
        controller.callWorkers(address(nft), abi.encodeWithSignature("mintFree(uint256)", 2), 0, 2, 0, true);
        vm.stopBroadcast();
    }
}

contract UpgradeController is Script, Setup {
    function run() public {
        vm.startBroadcast();
        Controller newControllerLogic = new Controller();
        proxyAdmin.upgrade(proxy, address(newControllerLogic));
        vm.stopBroadcast();
    }
}

contract DeployAndTestMecha is Script, Setup {
    function run() public {
        vm.startBroadcast();
        MechaPixels mechaPixels = new MechaPixels();
        mechaPixels.setPaused(false);

        controller.callWorkers(address(mechaPixels), abi.encodeWithSignature("mint(uint256)", 1), 0, 100, 0, true);
        vm.stopBroadcast();
    }
}

contract DeployAndTestNaka is Script, Setup {
    function run() public {
        vm.startBroadcast();
        Nakamiga naka = new Nakamiga();
        naka.togglePublicState();

        controller.callWorkers(address(naka), abi.encodeWithSignature("mint(uint256)", 2), 0, 50, 0, true);

        vm.stopBroadcast();
    }
}

contract DeployAndTestAcid is Script, Setup {
    function run() public {
        vm.startBroadcast();
        Multitest multi = new Multitest();
        controller.callWorkers(address(multi), abi.encodeWithSignature("mint(uint256)", 1), 0, 50, 0, true);
        vm.stopBroadcast();
    }
}