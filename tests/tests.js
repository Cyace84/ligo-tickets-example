const { rejects, strictEqual } = require("assert");
const { Tezos, signerAlice, alice } = require("./utils/cli");
const { migrate } = require("../scripts/helpers");
const { MichelsonMap } = require("@taquito/michelson-encoder/");

describe("test", async function () {
  Tezos.setSignerProvider(signerAlice);
  let contract;
  let deployedContract;
  before(async () => {
    try {
      deployedContract = await migrate(Tezos, "Ticketer", {
        tickets: MichelsonMap.fromLiteral({}),
        ticket_id: 0,
      });
      contract = await Tezos.contract.at(deployedContract);
    } catch (e) {
      console.log(e);
    }
  });

  describe("Testing entrypoint: Mint", async function () {
    it("sssss", async function () {
      // const op = await contract.methods
      //   .receive([deployedContract, "super", 10])
      //   .send();
      const op = await contract.methods.mint("super").send();
      await op.confirmation();
      const storage = await contract.storage();
      const ticket = await storage.tickets.get(0);
      console.log(ticket);
    });
  });
});
