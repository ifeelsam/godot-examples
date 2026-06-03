# Seeker Arcade

Three fully playable Godot 4 games that use [Mobile Wallet Kit](https://github.com/ifeelsam/godot-skr-mwa)
to connect a Solana Mobile / Seeker wallet and sign in-game actions.

Each game is a standalone Godot project and vendors the `MobileWalletKit` addon.

## Games

### Coin Flip (`coin-flip/`)
A press-your-luck prediction game. Set a stake, then **call** heads or tails.
Every correct call doubles your pot (double-or-nothing); one wrong call wipes it.
Cash out to bank the pot before your luck runs out. Best streak and best bank are
saved between sessions. When a wallet is connected, each cash-out is signed by the
wallet as a "proof of bank" receipt.

### Seeker Dash (`seeker-dash/`)
A side-scrolling platformer — run, jump, collect coins, stomp enemies, and reach
the flag at the end of the level. Touch controls (or keyboard) work on desktop and
mobile. When a wallet is connected, every 5 coins triggers a **checkpoint signature**
(mid-run MWA demo), and crossing the finish line signs a **level-clear receipt**
with your time, coin count, stomps, and deaths.

### Click Rush (`click-rush/`)
A 30-second reaction game. Targets pop up, shrink, and vanish — tap them before
they disappear to build a combo multiplier (up to x8). Dodge the red bombs and
don't miss empty space or you'll lose one of your three lives. The longer you
survive, the faster and smaller the targets get. Your best score is saved, and
when the round ends your final score is signed by the connected wallet as a
high-score receipt.

## Running

1. Open `seeker-dash/`, `coin-flip/`, or `click-rush/` as a project in Godot 4.3+.
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

### iOS export (Click Rush)

Godot writes an Xcode tree into `click-rush/` (for example `Click Rush Seeker/`
and `Click Rush Seeker.xcodeproj/`). Those folders are gitignored and marked with
`.gdignore` so the editor does not treat them as `res://` game assets.

**Archive failed — provisioning:** If `xcodebuild` reports *no devices* or *no
profiles for `com.seeker.arcade.clickrush`*, Apple cannot create a development
provisioning profile until at least one device is registered for team
`application/app_store_team_id` in the iOS export preset:

1. Connect an iPhone/iPad with a USB cable (or register its UDID manually at
   [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/devices/list)).
2. Open `click-rush/Click Rush Seeker.xcodeproj` in Xcode, select the
   **Click Rush Seeker** target → **Signing & Capabilities**, choose your team,
   and enable **Automatically manage signing**.
3. In [Identifiers](https://developer.apple.com/account/resources/identifiers/list),
   ensure an App ID exists for `com.seeker.arcade.clickrush`.
4. Re-run **Project → Export → iOS** in Godot, or build/archive from Xcode.

To iterate on signing without Godot invoking `xcodebuild`, enable **Export project
only** on the iOS preset, export once, then archive from Xcode after signing is
healthy.

**Harmless warnings:** `Can't open file from path 'res://Click Rush Seeker/...'`
before export usually means a stale export folder; re-export or delete
`Click Rush Seeker*` under `click-rush/` and reload the project.
`application/boot_splash/fullsize` comes from a Godot/iOS template version mismatch
and does not block the build.

## How wallet usage works in code

Both games create a `WalletAdapter`, connect its signals, and call:

- `connect_wallet()` — open the wallet chooser and authorize
- `is_wallet_connected()` / `get_connected_address()` — read session state
- `sign_message(text)` — sign checkpoint proofs and level-clear receipts
- `disconnect_wallet()` — end the session

See `coin_flip.gd` and `click_rush.gd` for the full, commented flow.
