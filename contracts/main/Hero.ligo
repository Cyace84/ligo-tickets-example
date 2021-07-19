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

function get_reg_arena_contract(
  const addr            : address)
                        : contract(arena_params_type) is
  case (Tezos.get_entrypoint_opt(
    "%receive_battle",
    addr)
    : option(contract(arena_params_type))) of
    Some(contr) -> contr
  | None -> (failwith("No pvp contract") : contract(arena_params_type))
  end;

function get_pvp_contract(
  const addr            : address)
                        : contract(send_pvp_params) is
  case (Tezos.get_entrypoint_opt(
    "%receive_battle",
    addr)
    : option(contract(send_pvp_params))) of
    Some(contr) -> contr
  | None -> (failwith("No pvp contract") : contract(send_pvp_params))
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
              (* Sort inventory *)
              const sorted_items = if abs(next_slot_item - 1n) = 0n
              then updated_tickets
              else block {
                const sorted =
                if abs(next_slot_item - 1n) = item_id
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
                end
              } with sorted;

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
                  next_slot_item    = abs(next_slot_item -1n);];
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

function reg_pvp (
  const item_id         : item_id_type;
  var s                 : storage_type)
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
          const contr = get_reg_arena_contract(game_server);
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
          const result = case updated_items of
            record[ticket; updated_tickets] -> block {
              (* Sort inventory *)
              const sorted_items = if abs(next_slot_item - 1n) = 0n
              then updated_tickets
              else block {
                const sorted =
                if abs(next_slot_item - 1n) = item_id
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
                end
              } with sorted;

              const r = record[
                arena_pass = ticket;
                hero_stats = record[
                  lvl    = lvl;
                  hp     = hp;
                  damage = damage;
                  str    = stats.str;
                  con    = stats.con;
                  dex    = stats.dex;
                  acc    = stats.acc;
                ]
              ];
              const op = Tezos.transaction (
                r,
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
                  next_slot_item    = abs(next_slot_item -1n);];
                stats        = stats;
                equip        = equip;
                hp           = hp;
                damage       = damage;
                exp          = exp;
                lvl          = lvl;
              ];
            } with (list[op], up)
          end;
        } with result
      end
  end;
function go_pvp (
  const params          : send_pvp_params;
  var s                 : storage_type)
                        : return is
  case s of
    record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] -> block {
      const contr = get_pvp_contract(game_server);
      const op = Tezos.transaction (
        params,
        0mutez,
        contr
      );
      const up : storage_type = record[
        owner        = owner;
        game_server  = game_server;
        nickname     = nickname;
        inventory    = inventory;
        stats        = stats;
        equip        = equip;
        hp           = hp;
        damage       = damage;
        exp          = exp;
        lvl          = lvl;
      ];
    } with (list[op], up)
  end

type parameter_type     is
    Activate_account      of item_id_type
  | Equip_item            of item_id_type
  | Unequip_item          of slot_id_type
  | Use_item              of item_id_type
  | Receive_item          of consumable_item_type
  | Reg_arena             of item_id_type
  | Pvp                   of send_pvp_params


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
    | Reg_arena (params)       -> reg_pvp(params, s)
    | Pvp (params)             -> go_pvp (params, s)

  end