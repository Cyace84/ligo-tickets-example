function read_ticket(
  const ticket  : consumable_item_type)
                : ticket_info_type is
  case (Tezos.read_ticket (ticket)) of
    (content, _) -> case content of
      (addr, x) ->
        case x of
          (payload, amt) -> record[
              ticketer  = addr;
              id        = payload.id;
              name      = payload.name;
              value     = payload.value;
              amount    = amt;
            ]
        end
    end
  end