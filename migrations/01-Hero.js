const { migrate } = require("../scripts/helpers");
const fse = require("fs-extra");
const storage = require("../storage/Hero");

module.exports = async tezos => {
  // const contractAddress = await migrate(tezos, "Hero", storage);
  console.log(`Hero contract address: ${"contractAddress"}`);
};
// fse.outputFile(
//   "./scripts/sandbox/hero_latest.json",
//   JSON.stringify({ address: contractAddress }),
//   err => {
//     if (err) {
//       console.log(err);
//     } else {
//       console.log("The contract address was saved!");
//     }
//   },
// );
