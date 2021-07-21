type item_id_type       is nat

type weapon_ticket_type is [@layout:comb] record [
  id                      : item_id_type;
  name                    : string;
  damage                  : nat;
]

type weapon_type is ticket(weapon_ticket_type)

(* item type ids
  0 - registration ticket
  1 - arena pass
  2 - random weapon
  3 - noob stats point
  4 - money
  5 - exp *)

type consumable_type    is [@layout:comb] record [
  id                      : item_id_type;
  name                    : string;
  value                   : nat;
]

type consumable_item_type is ticket(consumable_type)

type ticket_info_type   is  record[
  ticketer                : address;
  id                      : nat;
  name                    : string;
  value                   : nat;
  amount                  : nat;
]