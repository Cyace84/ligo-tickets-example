#include "../partial/Items.ligo"
#include "../partial/HeroTypes.ligo"

function get_reg_contract(
  const addr            : address)
                        : contract(consumable_item_type) is
  case (Tezos.get_entrypoint_opt(
    "%registration",
    addr)
    : option(contract(consumable_item_type))) of
    Some(contr) -> contr
  | None -> (failwith("No game contract") : contract(consumable_item_type))
  end;

function activate_account(
  const item_id         : item_id_type;
  const s               : storage_type)
                        : return is
  case s of
    record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] ->
      case inventory of
        record[
          weapons;
          consumable_items;
          inventory_size;
          next_slot_weapon;
          next_slot_item;
        ]             -> block {
          const contr : contract(consumable_item_type) =
            get_reg_contract(game_server);
          const updated_items =
          case Big_map.get_and_update(
            item_id,
            (None: option(consumable_item_type)),
            consumable_items) of
            (t, _updated_tickets) -> block {
              const ticket : consumable_item_type = case t of
                Some(ticket) -> ticket
              | None -> failwith("No reg ticket")
              end;
              const updated_tickets =_updated_tickets;
            } with record[ticket=ticket;updated_tickets=updated_tickets]
          end;
          const return = case updated_items of
            record[ticket; updated_tickets] -> block {

              const sorted_items = if abs(next_slot_item - 1n) = 1n
              then updated_tickets
              else case Big_map.get_and_update(
                abs(next_slot_item - 1n),
                (None: option(consumable_item_type)),
                updated_tickets) of
                (t, updated_tickets) ->
                  case Big_map.get_and_update(
                    item_id,
                    t,
                    updated_tickets
                  ) of
                    (_, sorted_tickets) -> sorted_tickets
                  end
              end;

              const op = Tezos.transaction (
                ticket,
                0mutez,
                contr
              );
              const up = record[
                owner        = owner;
                game_server  = game_server;
                nickname     = nickname;
                inventory    = record[
                  weapons           = weapons;
                  consumable_items  = sorted_items;
                  inventory_size    = inventory_size;
                  next_slot_weapon  = next_slot_weapon;
                  next_slot_item    = next_slot_item;];
                stats        = stats;
                equip        = equip;
                hp           = hp;
                damage       = damage;
                exp          = exp;
                lvl          = lvl;
              ];
            } with (list[op], up)
          end;
        } with return
      end
  end;

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


function receive_item (
  const params          : consumable_item_type;
  var s                 : storage_type)
                        : storage_type is
  block {
    var updated_storage : storage_type := s;
    case s of
      record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] -> {
        case (Tezos.read_ticket (params)) of
          (content, ticket) -> {
            case content of
              (addr, _data) -> {
                if addr = game_server then skip
                else failwith("No game_server");
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
                        game_server  = game_server;
                        nickname     = nickname;
                        inventory    = record[
                          weapons           = weapons;
                          consumable_items  = updated_tickets;
                          inventory_size    = inventory_size;
                          next_slot_weapon  = next_slot_weapon;
                          next_slot_item    = next_slot_item + 1n;];
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
    Activate_account      of item_id_type
  | Equip_item            of item_id_type
  | Unequip_item          of slot_id_type
  | Use_item              of item_id_type
  | Receive_item          of consumable_item_type


function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
      Activate_account (params) -> activate_account(params, s)
    | Equip_item (params)      -> ((nil : list (operation)), equip_item (params, s))
    | Unequip_item (params)    -> ((nil : list (operation)), unequip_item (params, s))
    | Use_item   (params)      -> ((nil : list (operation)), use_item (params, s))
    | Receive_item (params)    -> ((nil : list (operation)), receive_item (params, s))

  end


// function activate_account(
//   const item_id         : item_id_type;
//   const s               : storage_type)
//                         : return is
//   block {
//     var result : return := ((nil : list (operation)), s);
//     case s of
//       record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] -> {
//         case inventory of
//           record[
//             weapons;
//             consumable_items;
//             inventory_size;
//             next_slot_weapon;
//             next_slot_item;
//           ]           -> {
//           const contr : contract(consumable_item_type) =
//                 get_reg_contract(game_server);
//           const updated_items = case Big_map.get_and_update(
//             item_id,
//             (None: option(consumable_item_type)),
//             consumable_items) of
//             (t, _updated_tickets) -> block {

//               const ticket : consumable_item_type = case t of
//                 Some(ticket) -> ticket
//               | None -> failwith("No reg ticket")
//               end;

//               // if abs(next_slot_item) - 1n = 1n then skip
//               // else {

//               // }
//               const updated_tickets = _updated_tickets;
//             } with record[ticket=ticket;updated_tickets=_updated_tickets]
//           end;

//           case updated_items of
//             record[ticket; updated_tickets] -> {
//               result := (
//                 list [
//                   Tezos.transaction (
//                     ticket,
//                     0mutez,
//                     contr
//                   )
//                 ],
//                 record[
//                   owner        = owner;
//                   game_server  = game_server;
//                   nickname     = nickname;
//                   inventory    = record[
//                     weapons           = weapons;
//                     consumable_items  = updated_tickets;
//                     inventory_size    = inventory_size;
//                     next_slot_weapon  = next_slot_weapon;
//                     next_slot_item    = next_slot_item;];
//                   stats        = stats;
//                   equip        = equip;
//                   hp           = hp;
//                   damage       = damage;
//                   exp          = exp;
//                   lvl          = lvl;
//                 ]
//               );
//             }
//           end;
//           }
//         end;
//       }
//     end;

//   } with result