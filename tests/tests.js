const { rejects, strictEqual } = require("assert");
const { Tezos, signerAlice, signerBob, alice, bob } = require("./utils/cli");
const { migrate } = require("../scripts/helpers");
const { MichelsonMap } = require("@taquito/michelson-encoder/");
const { address } = require("../scripts/sandbox/core_latest.json");

let storage = require("../storage/Hero");
describe("test", async function () {
  Tezos.setSignerProvider(signerAlice);
  let gameContract;
  let aliceAcc;
  let bobAcc;
  let aliceContract;
  let bobContract;
  let deployedContract;
  before(async () => {
    try {
      aliceAcc = await migrate(Tezos, "Hero", storage);
      storage.owner = bob.pkh;
      Tezos.setSignerProvider(signerBob);
      bobAcc = await migrate(Tezos, "Hero", storage);
      bobContract = await Tezos.contract.at(bobAcc);
      Tezos.setSignerProvider(signerAlice);
      gameContract = await Tezos.contract.at(address);
      aliceContract = await Tezos.contract.at(aliceAcc);
    } catch (e) {
      console.log(e);
    }
  });

  describe("Testing entrypoint: Send invite", async function () {
    it("Should allow issuance of an invitation from Alice and Bob", async function () {
      const op_1 = await gameContract.methods.send_invite(aliceAcc).send();
      await op_1.confirmation();
      const op_2 = await gameContract.methods.send_invite(bobAcc).send();
      await op_2.confirmation();
      const storageA = await aliceContract.storage();
      const storageB = await bobContract.storage();

      const ticketA = await storageA.inventory.consumable_items.get(1);
      const ticketB = await storageB.inventory.consumable_items.get(1);

      strictEqual(ticketA.value.name, "Reg ticket");
      strictEqual(ticketB.value.name, "Reg ticket");
    });
  });

  describe("Testing entrypoint: Activate account", async function () {
    it("Should allow to activate account and receive bonus", async function () {
      const op_1 = await aliceContract.methods.activate_account(1).send();
      await op_1.confirmation();
      const op_2 = await bobContract.methods.activate_account(1).send();
      await op_2.confirmation();
      const storageA = await aliceContract.storage();
      const gameStorage = await gameContract.storage();
      const reg = await gameStorage.accounts.get(aliceAcc);
      const ticketPoints = await storageA.inventory.consumable_items.get(1);

      strictEqual(reg.addr, aliceAcc);
      strictEqual(ticketPoints.value.name, "Noob stat point");
    });
  });
  describe("Testing entrypoint: Buy item", async function () {
    it("Should allow to buy pvp pass", async function () {
      const op_1 = await aliceContract.methods.buy_item(1).send();
      await op_1.confirmation();

      const op_2 = await bobContract.methods.buy_item(1).send();
      await op_2.confirmation();

      const storageA = await aliceContract.storage();
      // const gameStorage = await gameContract.storage();
      // const reg = await gameStorage.accounts.get(aliceAcc);
      const ticket = await storageA.inventory.consumable_items.get(2);

      strictEqual(ticket.value.name, "Arena pass");
    });
  });
  describe("Testing entrypoint: Reg pvp arena", async function () {
    it("Revert registration to the arena without a proper ticket", async function () {
      await rejects(aliceContract.methods.reg_arena(1).send(), err => {
        strictEqual(err.message, "Core/not-pvp-ticket");
        return true;
      });
    });

    it("Should allow to registration pvp, Alice in queue", async function () {
      const op_1 = await aliceContract.methods.reg_arena(2).send();
      await op_1.confirmation();
      const gameStorage = await gameContract.storage();
      const pendingAlice = await gameStorage.arena.lobby.get(1);
      strictEqual(pendingAlice.addr, aliceAcc);
    });

    it("Should allow Bob to register to the arena, and immediately start the duel, because Alice is waiting", async function () {
      const op_1 = await bobContract.methods.reg_arena(2).send();
      await op_1.confirmation();

      const gameStorage = await gameContract.storage();
      const duel = await gameStorage.arena.duels.get(1);

      strictEqual(duel.hero_1, aliceAcc);
      strictEqual(duel.hero_2, bobAcc);
    });
  });

  describe("Testing entrypoint: Go pvp", async function () {
    // it("Revert registration to the arena without a proper ticket", async function () {
    //   await rejects(aliceContract.methods.reg_arena(1).send(), err => {
    //     strictEqual(err.message, "Core/not-pvp-ticket");
    //     return true;
    //   });
    // });

    it("Should allow Alice pass her pvp actions", async function () {
      const op_1 = await aliceContract.methods
        .pvp("head", "unit", "head", "unit")
        .send();
      await op_1.confirmation();

      const gameStorage = await gameContract.storage();
      const duel = await gameStorage.arena.duels.get(1);
      const round = await duel.rounds.get(duel.next_round.toNumber());
      const a = await round.actions.get(aliceAcc);
      console.log(a);
      // strictEqual(duel.hero_1, aliceAcc);
      // strictEqual(duel.hero_2, bobAcc);
    });

    it("Should allow Bob pass his pvp actions and die from Alice", async function () {
      const op_1 = await aliceContract.methods
        .pvp("body", "unit", "body", "unit")
        .send();
      await op_1.confirmation();

      const gameStorage = await gameContract.storage();
      const duel = await gameStorage.arena.duels.get(1);
      console.log(duel);
      // strictEqual(duel.hero_1, aliceAcc);
      // strictEqual(duel.hero_2, bobAcc);
    });
  });
});
