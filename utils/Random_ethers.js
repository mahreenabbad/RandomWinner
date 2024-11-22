const { ethers, artifacts } = require("hardhat");
require("dotenv").config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
async function main() {
  const rpcUrl = `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`;

  const contractAddress = "0x682Fe67b7BcAD35Bced26618022FCf1A1FEA494C";

  const provider = new ethers.JsonRpcProvider(rpcUrl, undefined, {
    staticNetwork: true,
  });
  const PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log("signer :", signer);

  const recipientAddress = "0x117230682974d73f2DB5C21F0268De2fACB0119f"; // Address to receive the NFT
  const uri =
    "https://aquamarine-dear-whitefish-514.mypinata.cloud/ipfs/QmPyJBR2DgwnGEk8sQSfbwsGQgotNXBAMoHohQ9yZ2y9y4";

  const RandomArtifact = await artifacts.readArtifact("Random"); // Console the ABI
  const randomAbi = RandomArtifact.abi;

  const randomContract = new ethers.Contract(
    contractAddress,
    randomAbi,
    signer
  );

  try {
    const ticketMinted = await randomContract.mintTicket(recipientAddress, uri);

    console.log("ticketMinted :", ticketMinted);
  } catch (error) {
    console.error("Transaction failed:", error.message || error);
  }
  try {
    const tx = await randomContract.randomWinner();

    console.log("Random winner requested successfully:", tx);
  } catch (error) {
    console.error("Error requesting random winner:", error.message || error);
  }

  // Fetch current winner
  try {
    const currentWinner = await randomContract.currentWinner();
    if (currentWinner === ethers.ZeroAddress) {
      console.log("No winner selected yet.");
    } else {
      console.log("Current winner address:", currentWinner);
    }
  } catch (error) {
    console.error("Error fetching winner:", error.message || error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
