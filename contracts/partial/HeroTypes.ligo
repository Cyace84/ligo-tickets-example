type slot_id_type       is nat

type map_items_type is big_map(slot_id_type, consumable_item_type)

type inventory_type     is [@layout:comb] record [
    weapons              : big_map(slot_id_type, weapon_type);
    consumable_items     : map_items_type;
    inventory_size       : nat;
    next_slot_weapon     : slot_id_type;
    next_slot_item       : slot_id_type;
]

type return_consumable_item is [@layout:comb] record[
  ticket                      : consumable_item_type;
  updated_tickets             : map_items_type
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
  game_server            : address;
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


type target_type        is
  Head
| Body

type duel_action_type   is
  Attack                 of target_type
| Deffend                of target_type
| Use                    of item_id_type

type send_pvp_params is (duel_action_type * duel_action_type)

type hero_stats_type    is [@layout:comb] record [
  lvl                     : nat;
  hp                      : nat;
  damage                  : nat;
  str                     : nat;
  con                     : nat;
  dex                     : nat;
  acc                     : nat;
]

type arena_params_type  is [@layout:comb] record [
  arena_pass              : consumable_item_type;
  hero_stats              : hero_stats_type;
]