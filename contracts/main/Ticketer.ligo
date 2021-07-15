type ticket_value_type  is string

type ticket_type        is ticket(ticket_value_type)



type storage_type       is [@layout:comb] record [
  tickets                : big_map(nat, ticket_type );
  ticket_id              : nat
]

type send_parameter_type is [@layout:comb] record [
  destination              : contract(ticket_type);
  ticket_id                : nat
]

type mint_to_type       is [@layout:comb] record [
  destination            : address;
  value                  : string;
  amount                 : nat;
]

type parameter_type     is
    Mint                  of string
  | Mint_to               of mint_to_type
  | Receive               of ticket_type
  | Send                  of send_parameter_type

type return             is list (operation) * storage_type

type l                  is big_map(nat, ticket_type)

const ss : l = big_map[];


function get_receive_contract(
  const contract_address : address)
                        : contract(ticket_type) is
  case (Tezos.get_entrypoint_opt(
    "%receive_str_ticket",
     contract_address)
     : option(contract(ticket_type))) of
    Some(contr) -> contr
    | None -> (failwith("No receiver contract") : contract(ticket_type))
  end;

function mint_ticket (
    const i             : string;
    var s               : storage_type)
                        : return is
  block {
    const new_ticket : ticket_type = Tezos.create_ticket (i, 42n);
    var result : return := ((nil : list (operation)), s);

    case s of
      record[tickets; ticket_id] -> {
        const updated_storage =
            case Big_map.get_and_update(ticket_id, (Some (new_ticket)), tickets) of
              (_, updated_tickets) ->
                record[
                  tickets    = updated_tickets;
                  ticket_id  = ticket_id + 1n;
                ]
            end;
        result := ((nil : list (operation)), updated_storage)
      }
    end;

   } with result;


function send_ticket (
  const params          : send_parameter_type;
  var s                 : storage_type)
                        : return is
  block {
    var result : return := ((nil : list (operation)), s);

    case s of
      record[tickets; ticket_id] -> {
        case Big_map.get_and_update(
          params.ticket_id,
          (None: option(ticket_type)),
          tickets) of
          (t, updated_tickets) -> {
            const ticket : ticket_type = case t of
              Some(ticket) -> ticket
            | None -> failwith("No tickets")
            end;
            result := (
              list[
                Tezos.transaction(
                  ticket,
                  0mutez,
                  params.destination
                )
              ],
              record[
                tickets    = updated_tickets;
                ticket_id  = ticket_id;
              ]
            );
          }
        end
      }
    end;

  } with result

function receive (
  const params          : ticket_type;
  var s                 : storage_type)
                        : return is
block {
  var result : return := ((nil : list (operation)), s);

  case result.1 of
    record[tickets; ticket_id] -> {
      case (Tezos.read_ticket (params)) of
        (content, ticket) -> {
          case content of
            (addr, x) -> {
              case x of
                (payload,amt) -> {
                  skip
                } end;
              if addr = Tezos.self_address then skip
              else failwith("Unknown ticketer")
          } end;
          case Big_map.get_and_update(ticket_id, (Some (ticket)), tickets) of
            (_, updated_tickets) -> {
              result := (
                (nil : list (operation)),
                record[
                  tickets    = updated_tickets;
                  ticket_id  = ticket_id + 1n;
                ]
              );
          } end;
      } end;
  } end;
} with result

function mint_to (
    const params        : mint_to_type;
    const _s            : storage_type)
                        : return is
  block {
    const ticket : ticket_type = Tezos.create_ticket (params.value, params.amount);
    const contr : contract(ticket_type)  = get_receive_contract(params.destination);

    const op = Tezos.transaction(ticket, 0mutez, contr);

   } with (list[op], _s);


function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
      Mint (params)     -> mint_ticket(params, s)
    | Mint_to (params)  -> mint_to(params, s)
    | Receive (params)  -> receive(params, s)
    | Send (params)     -> send_ticket(params, s)
  end
