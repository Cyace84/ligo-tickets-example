
type registration_params_type is [@layout:comb] record [
    registration_ticket    : consumable_item_type;
    callback              : contract(list(consumable_item_type));
  ]

type account_type       is [@layout:comb] record [
    account               : address;
]

