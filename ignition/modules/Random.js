const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const subscriptionId =
  "18519595116180166042061678876817691063258995766210222005326249960568868181746";

module.exports = buildModule("RandomModule", (m) => {
  const random = m.contract("Random", [subscriptionId]);

  return { random };
});
