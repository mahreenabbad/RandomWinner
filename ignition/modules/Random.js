const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const subscriptionId =
  "48174830142776465173713416888080785440723938908336982394441279292739615684127";

module.exports = buildModule("RandomModule", (m) => {
  const random = m.contract("Random", [subscriptionId]);

  return { random };
});
