CHICHARON BEAT

Gameplay
- A one-piece trial run teaches the timing before Round 1. Trial results do
  not change collected, wasted, combo, or score values.
- Five rounds: Easy, Medium, Medium, Hard, Hard.
- The green timing layer fills from left to right.
- Every chicharon in the round has one static needle.
- Press Space or left-click when the green comes close to a needle. The
  success window is intentionally wider than an exact visual touch.
- A landed piece may be removed at any time; taking it early produces a raw
  or undercooked result instead of blocking input.
- Seven wasted pieces fail the game. At least 18 collected pieces are needed
  after the fifth round.

HUD assets
- assets/ui/chicharon_round_panel.png
- assets/ui/chicharon_round_complete.png
- assets/ui/chicharon_performance_panel.png
- assets/ui/chicharon_combo_counter.png
- assets/gameplay/take_out_indicator_panel.png
- assets/gameplay/take_out_indicator_green.png
- assets/gameplay/take_out_indicator_frame.png
- assets/gameplay/take_out_indicator_needle.png

The controller uses SharedDialogue with the vendor_chicharon portraits and
SharedCursor. Instructions, success, and failure use the shared game-flow
screens.
Vendor feedback and round-to-round lines auto-hide while the next active
round continues; they do not pause the timing sweep or block takeout input.
After the trial and every ROUND COMPLETE display, the game waits for Space or
a left-click. Each normal round then begins after a quick three-sound 3-2-1
countdown.
