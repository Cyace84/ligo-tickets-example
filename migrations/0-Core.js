const { migrate } = require("../scripts/helpers");
const storage = require("../storage/Core");
const fse = require("fs-extra");

module.exports = async tezos => {
  const contractAddress = await migrate(tezos, "Core", storage);
  console.log(`Core contract address: ${contractAddress}`);

  fse.outputFile(
    "./scripts/sandbox/core_latest.json",
    JSON.stringify({ address: contractAddress }),
    err => {
      if (err) {
        console.log(err);
      } else {
        console.log("The contract address was saved!");
      }
    },
  );
};
