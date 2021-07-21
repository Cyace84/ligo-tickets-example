#include "../partial/Items.ligo"
#include "../partial/HeroTypes.ligo"
#include "../partial/Common.ligo"
#include "../partial/HeroMethods.ligo"

type parameter_type     is
    Activate_account      of item_id_type
  | Equip_item            of item_id_type
  | Unequip_item          of slot_id_type
  | Use_item              of item_id_type
  | Buy_item              of item_id_type
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
    | Buy_item (params)        ->  buy_item (params, s)
    | Receive_item (params)    -> ((nil : list (operation)), receive_item (params, s))
    | Reg_arena (params)       -> reg_arena(params, s)
    | Pvp (params)             -> go_pvp (params, s)

  end