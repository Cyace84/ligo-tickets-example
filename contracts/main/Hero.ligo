#include "../partial/Items.ligo"

#include "../partial/HeroTypes.ligo"

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
  const item_id        : item_id_type;
  const s               : storage_type)
                        : storage_type is
  block {
    skip
} with s

// function get_free_slot (
//   const s               : storage_type)
//                         : slot_id_type is
// block {

//   const items = s.inventory.consumable_items;
//   const inv_size = s.inventory.inventory_size;
//     // case s.inventory of
//     //   record[weapons; consumable_items; inventory_size] -> consumable_items
//   // end;
//   var free_slot : nat := 1n;
//   // for i := 1 to int ( inv_size + 1n) block {
//   //   case items[abs(inv_size + 1n - 1)] of
//   //     Some(consumable_item_type) -> skip
//   //   | None                       -> free_slot := abs(inv_size + 1n - i)
//   //   end;
//   // }
// } with free_slot

function receive_item (
  const params          : consumable_item_type;
  var s                 : storage_type)
                        : storage_type is
block {
  var updated_storage : storage_type := s;
  case s of
    record[owner; ticketer; nickname; inventory; stats; equip; hp; damage; exp; lvl ] -> {
      case (Tezos.read_ticket (params)) of
        (content, ticket) -> {
          case content of
            (addr, _data) -> {
              if addr = ticketer then skip
              else failwith("No ticketer");
              // case data of
              //   (payload, _amt) -> {
              //     if payload.id = 0n then skip
              //     else failwith("No registration ticket")
              //   }
              // end;
          } end;
          case inventory of
            record[
              weapons;
              consumable_items;
              inventory_size;
              next_slot_weapon;
              next_slot_item;
              weapon_count;
              item_count
            ]           -> {
              if inventory_size >= next_slot_item
              then skip
              else failwith("Full inventory");

              case Big_map.get_and_update(
                next_slot_item,
                Some (ticket),
                consumable_items) of
                (_, updated_tickets) -> {
                  updated_storage :=
                    record[
                      owner        = owner;
                      ticketer     = ticketer;
                      nickname     = nickname;
                      inventory    = record[
                        weapons           = weapons;
                        consumable_items  = updated_tickets;
                        inventory_size    = inventory_size;
                        next_slot_weapon  = next_slot_weapon;
                        next_slot_item    = next_slot_item + 1n;
                        weapon_count      = weapon_count;
                        item_count        = item_count;];
                      stats        = stats;
                      equip        = equip;
                      hp           = hp;
                      damage       = damage;
                      exp          = exp;
                      lvl          = lvl;
                    ]
                }
              end;
            }
          end;
        }
      end
    }
  end;
} with updated_storage


type parameter_type     is
    Equip_item            of item_id_type
  | Unequip_item          of slot_id_type
  | Use_item              of item_id_type
  | Receive_item          of consumable_item_type


function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
      Equip_item (params)      -> ((nil : list (operation)), equip_item (params, s))
    | Unequip_item (params)    -> ((nil : list (operation)), unequip_item (params, s))
    | Use_item   (params)      -> ((nil : list (operation)), use_item (params, s))
    | Receive_item (params)    -> ((nil : list (operation)), receive_item (params, s))

  end

