module arcade::game;

use arcade::coin::COIN;
use sui::balance::Balance;
use sui::coin::Coin;
use sui::event::emit;

const ECallerNotHouse: u64 = 5;
const EInsufficientBalance: u64 = 6;

/// 单人游戏
public struct SingleGame has key {
    id: UID,
    balance: Balance<COIN>,
    public_key: vector<u8>,
    owner: address,
    status: u8,
}

public fun create(public_key: vector<u8>, coin: Coin<COIN>, ctx: &mut TxContext) {
    let amount = coin.value();
    assert!(amount > 0, EInsufficientBalance);

    let id = object::new(ctx);
    let game_id = object::uid_to_inner(&id);

    let game = SingleGame {
        id,
        balance: coin.into_balance(),
        owner: ctx.sender(),
        public_key,
        status: 0,
    };

    transfer::transfer(game, ctx.sender());
    emit(CreateGame {
        game_id,
        owner: ctx.sender(),
        balence: amount,
    });
}

#[allow(lint(self_transfer))]
public fun withdraw(game: SingleGame, ctx: &mut TxContext) {
    assert!(ctx.sender() == game.owner, ECallerNotHouse);
    let SingleGame { id, balance, public_key: _, owner: _, status: _ } = game;
    emit(Withdraw {
        game_id: object::uid_to_inner(&id),
        owner: ctx.sender(),
        balence: balance.value(),
    });

    id.delete();
    transfer::public_transfer(balance.into_coin(ctx), ctx.sender());
}

public fun balance(self: &SingleGame): u64 {
    self.balance.value()
}

// --------------- EVENTS ---------------

public struct CreateGame has copy, drop {
    game_id: ID,
    owner: address,
    balence: u64,
}

public struct Withdraw has copy, drop {
    game_id: ID,
    owner: address,
    balence: u64,
}
