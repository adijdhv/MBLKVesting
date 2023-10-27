const { expect } = require("chai");

describe("Proxy contract", function () {
  let Proxy;
  let proxy;
  let StakingPool;
  let stakingPool;
  let AutoTransfer;
  let autoTransfer;
  let owner;
  let admin;
  let beneficiary;

  before(async function () {
    [owner, admin, beneficiary] = await ethers.getSigners();
    const initial_supply = ethers.utils.parseEther('100000000000');
    LPStaked = await ethers.getContractFactory("LPStaked");  
    slpToken = await LPStaked.deploy();
    MBLKStaked = await ethers.getContractFactory("MBLKStaked");  
    smblkToken = await MBLKStaked.deploy();
    MBLK = await ethers.getContractFactory("MBLK");  
    mblkToken = await MBLK.deploy(initial_supply);
    LPTest = await ethers.getContractFactory("LPtest");  
    lpToken = await LPTest.deploy(initial_supply);

     StakingPool = await ethers.getContractFactory("MBLKStakingPool");  
    stakingPool = await StakingPool.deploy(mblkToken.address,smblkToken.address,slpToken.address,lpToken.address,admin.address);

    AutoTransfer = await ethers.getContractFactory("AutoTransfer");  
    autoTransfer = await AutoTransfer.deploy(mblkToken.address);

     Proxy = await ethers.getContractFactory("Proxy"); 
     proxy = await Proxy.deploy(stakingPool.address, autoTransfer.address);

     await stakingPool.connect(owner).addAdmin(proxy.address);
     console.log("PROXY CONTRACT IS ADMIN NOW!!")
     await autoTransfer.connect(owner).addAdmin(proxy.address)
     await proxy.connect(owner).addAdmin(admin.address);
  });

  it("should allow the owner to set the StakingPool contract address", async function () {
    const newStakingPool = await StakingPool.deploy();
    await proxy.setStakingPoolContractAddress(newStakingPool.address);
    const updatedAddress = await proxy.StakingPool();
    expect(updatedAddress).to.equal(newStakingPool.address);
  });

  it("should allow the owner to set the AutoTransfer contract address", async function () {
    const newAutoTransfer = await AutoTransfer.deploy();
    await proxy.setVestingContractAddress(newAutoTransfer.address);
    const updatedAddress = await proxy.AutoTransfer();
    expect(updatedAddress).to.equal(newAutoTransfer.address);
  });

  it("should allow an admin to add another admin", async function () {
    await proxy.addAdmin(beneficiary.address);
    const isAdmin = await proxy.isAdmin(beneficiary.address);
    expect(isAdmin).to.be.true;
  });

  it("should allow an admin to remove another admin", async function () {
    await proxy.removeAdmin(admin.address);
    const isAdmin = await proxy.isAdmin(admin.address);
    expect(isAdmin).to.be.false;
  });

 });
