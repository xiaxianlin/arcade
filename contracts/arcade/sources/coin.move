module arcade::coin;

use std::option::none;
use std::string::{Self, String};
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin, TreasuryCap};
use sui::sui::SUI;
use sui::token::{Self, Token, ActionRequest};

public struct COIN has drop {}

#[allow(lint(coin_field))]
public struct CoinStore has key {
    id: UID,
    profits: Balance<SUI>,
    gem_treasury: TreasuryCap<COIN>,
}

fun init(otw: COIN, ctx: &mut TxContext) {
    let (treasury_cap, coin_metadata) = coin::create_currency(
        otw,
        0,
        b"ARCADE",
        b"ARCADE Coin",
        b"In-game currency for arcade",
        none(),
        ctx,
    );

    let (mut policy, cap) = token::new_policy(&treasury_cap, ctx);

    token::allow(&mut policy, &cap, buy_action(), ctx);
    token::allow(&mut policy, &cap, token::spend_action(), ctx);

    transfer::share_object(CoinStore {
        id: object::new(ctx),
        gem_treasury: treasury_cap,
        profits: balance::zero(),
    });

    transfer::public_freeze_object(coin_metadata);
    transfer::public_transfer(cap, ctx.sender());
    token::share_policy(policy);
}

public fun apply_coin(
    self: &mut CoinStore,
    payment: Coin<SUI>,
    ctx: &mut TxContext,
): (Token<COIN>, ActionRequest<COIN>) {
    let amount = payment.value();
    let purchased = amount * 1000;

    coin::put(&mut self.profits, payment);

    let gems = token::mint(&mut self.gem_treasury, purchased, ctx);
    let req = token::new_request(buy_action(), purchased, none(), none(), ctx);

    (gems, req)
}

public fun return_coin() {}

public fun buy_action(): String { string::utf8(b"apply") }
