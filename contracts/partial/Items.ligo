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
  2 - random weapon *)

type consumable_type    is [@layout:comb] record [
  id                      : item_id_type;
  name                    : string;
  value                   : nat;
]

type consumable_item_type is ticket(consumable_type)
