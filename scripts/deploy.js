async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  //const Token = await ethers.getContractFactory("Token");
  // const token = await Token.deploy(
  //   "Test Token",
  //   "TT",
  //   "1000000000000000000000000"
  // );
const mblk_address = "0x16552399d27796eFC861a37bAcB7893eadd60643"
  //console.log("Token address:", token.address);

  const TokenVesting = await ethers.getContractFactory("MBLKVesting");
  const tokenVesting = await TokenVesting.deploy(mblk_address);
  console.log("TokenVesting address:", tokenVesting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
