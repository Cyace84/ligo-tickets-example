type slot_id_type       is nat

type inventory_type     is [@layout:comb] record [
    weapons              : big_map(slot_id_type, weapon_type);
    consumable_items     : big_map(slot_id_type, consumable_item_type);
    inventory_size       : nat;
    next_slot_weapon     : slot_id_type;
    next_slot_item       : slot_id_type;
    weapon_count         : nat;
    item_count           : nat;
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
  ticketer               : address;
  nickname               : string;
  inventory              : inventory_type;
  stats                  : stats_type;
  equip                  : equip_type;
  hp                     : nat;
  damage                 : nat;
  exp                    : nat;
  lvl                    : nat;
]
type return             is list (operation) * storage_type
