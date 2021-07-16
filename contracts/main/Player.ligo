#include "./partial/Items.ligo"

type str_ticket_type    is ticket(string)

type slot_id_type       is nat

type inventory_type     is [@layout:comb] record [
    weapons              : big_map(slot_id_type, weapon_type);
    consumable_items     : big_map(slot_id_type, consumable_item_type);
    inventory_size       : nat;
]

type equip_type         is [@layout:comb] record [
    weapon               : option(weapon_type);
]

(* str - strength
   con - constitution
   dex - dexterity
   acc - accuracy *)
type stats_type         is [@layout:comb] record [
  str               : nat;
  con               : nat;
  dex               : nat;
  acc               : nat;
]

type storage_type       is [@layout:comb] record [
  owner                  : address;
  nickname               : string;
  inventory              : inventory_type;
  stats                  : stats_type;
  equip                  : equip_type;
  hp                     : nat;
  damage                 : nat;
  exp                    : nat;
  lvl                    : nat;
]

// type item_count_type    is nat

// type use_item_type      is (item_id_type * item_count_type)

type return             is list (operation) * storage_type

type parameter_type     is
    Equip_item            of item_id_type
  | Unequip_item          of slot_id_type
  | Use_item              of item_id_type

function equip_item(
  const item_id         : item_id_type;
  const s               : storage_type)
                        : storage_type is
  block {
    // if Tezos.sender = s.owner then skip
    // else failwith("not-owner");
    skip

} with s

function unequip_item(
  const slot_id         : slot_id_type;
  const s               : storage_type)
                        : storage_type is
  block {
    skip
} with s


function use_item(
  const item_id         : item_id_type;
  const s               : storage_type)
                        : storage_type is
  block {
    skip
} with s


function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
      Equip_item (params)      -> ((nil : list (operation)), equip_item (params, s))
    | Unequip_item (params) -> ((nil : list (operation)), unequip_item (params, s))
    | Use_item   (params)      -> ((nil : list (operation)), use_item (params, s))

  end
