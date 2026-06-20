# Easter eggs

A few delights hidden in the app.

## The Beezle watermark

**Settings → Easter Eggs** on → a faint silhouette of Beezle (the app's ghost mascot) gently breathes in and out behind the main UI. The pulse period and peak opacity are configurable in the same Settings section:

- **Peak Opacity** slider — 0.05 to 1.00, in 0.05 steps. Default 0.20.
- **Pulse Period** stepper — 0 to 60 seconds. 0 holds Beezle steady at the peak opacity (no pulse). Default 12s.

When **Easter Eggs AND Colorful Mode** are both on, Beezle cycles through the rainbow as it pulses.

![Beezle watermark behind the UI](images/easter-egg-watermark.png)

## The home tab swap

With Easter Eggs on, the Home tab icon in the tab bar swaps from the default SF Symbol house to a custom Beezle icon. Subtle, but rewarding once you notice.

## The 7-tap chord

On the **Info** tab (home screen), scroll to the bottom and find the small version label that reads `#hackertracker iOS v6.0` (or whatever version you're on).

**Tap it seven times.** What follows is a small celebration and an iconic 1987 music video. You've been warned.

The seven-tap chord also flips on both Easter Eggs and Colorful Mode for you.

![Easter Eggs Enabled overlay](images/easter-eggs-enabled.png)

## How to find more

The hacker conference audience is good at finding hidden things. Some are mentioned here, some aren't. The source code is open — `grep` is your friend.

## Source

The Beezle watermark renderer lives in [`hackertracker/Views/ContentView.swift`](../hackertracker/Views/ContentView.swift) as `BeezleEasterEggOverlay`. The seven-tap handler is in [`hackertracker/Views/InfoView.swift`](../hackertracker/Views/InfoView.swift).
