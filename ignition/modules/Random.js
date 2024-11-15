const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const subscriptionId =
  "48174830142776465173713416888080785440723938908336982394441279292739615684127";
const vrfCoordinator = "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625";
const keyHash =
  "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c";
module.exports = buildModule("RandomModule", (m) => {
  const random = m.contract("Random", [
    subscriptionId,
    vrfCoordinator,
    keyHash,
  ]);

  return { random };
});
