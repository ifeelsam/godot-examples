# Seeker Arcade

Two tiny, fully playable Godot 4 games that use [Mobile Wallet Kit](https://github.com/ifeelsam/godot-skr-mwa)
to connect a Solana Mobile / Seeker wallet and sign in-game actions.

Each game is a standalone Godot project and vendors the `MobileWalletKit` addon.

## Games

### Coin Flip (`coin-flip/`)
Flip a coin, build a win/loss streak. When a wallet is connected, every win is
signed by the wallet as a lightweight "proof of win".

### Click Rush (`click-rush/`)
Tap the moving target as many times as you can in 15 seconds. When the round
ends, your final score is signed by the connected wallet as a high-score receipt.

## Running

1. Open either `coin-flip/` or `click-rush/` as a project in Godot 4.3+.
2. The `MobileWalletKit` addon is already enabled.
3. Press play. Both games are fully playable on desktop — the wallet features
   stay idle until a wallet is connected.

## Wallet connect

Wallet connect uses Solana Mobile Wallet Adapter and only works on an
**Android / Seeker** build with an MWA-compatible wallet installed. On desktop
the games detect that the bridge is unavailable and keep playing without it.

To export to Android, build the Mobile Wallet Kit Android plugin (see the
[SDK repo](https://github.com/ifeelsam/godot-skr-mwa)); the prebuilt debug and
release AARs are vendored under each game's `addons/MobileWalletKit/`.

## How wallet usage works in code

Both games create a `WalletAdapter`, connect its signals, and call:

- `connect_wallet()` — open the wallet chooser and authorize
- `is_wallet_connected()` / `get_connected_address()` — read session state
- `sign_message(text)` — sign the win / score proof
- `disconnect_wallet()` — end the session

See `coin_flip.gd` and `click_rush.gd` for the full, commented flow.
