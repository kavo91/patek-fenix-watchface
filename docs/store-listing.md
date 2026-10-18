# Connect IQ Store listing: Patek FENIX

Paste-ready values for apps.garmin.com/developer → Upload an App. Package: `bin/patekfenix-1.0.1.iq`
(build it with `./package.sh`). Manifest AppID 1b6651132c7147cb9345ef38a9e40800, version 1.0.1. Images are in `store/`.

Naming note: "Patek" and "fēnix" are other companies' marks. Garmin's review may ask for a different name;
if so, change `AppName` in `resources/strings/strings.xml`, the `word` array and initial in `Dial.logo`
(`source/Dial.mc`), rebuild the package and resubmit.

## Title (max 50)

Patek FENIX

## Description (max 4000)

Patek FENIX is a black and silver analog face for the fēnix 9 Pro 43mm.

The dial is a brushed sunburst with a minute track around the edge, polished dot markers and luminous dauphine hands. Two windows at 12 each show one thing you choose. The sub-dials at 3 and 9 show your data as a small gauge with a hand and a printed value. The sub-dial at 6 shows the moon phase, prints the date and points to it on a 1 to 31 track.

Two looks. Light is a silver dial with black print. Dark is a black dial with silver print. Auto mode switches at sunrise and sunset when your phone shares its weather location, or between the hours you set (7 am to 7 pm by default). You can also lock the face to light or dark.

Pick what each slot shows, in the Connect IQ app on your phone:
• 9 o'clock, 3 o'clock and 6 o'clock sub-dials: Body Battery, steps, watch battery, date, digital time, heart rate, calories, floors climbed or stress. The 6 o'clock dial can also show the moon phase with the date track.
• Each 12 o'clock window: day/month as numbers (11/09 or 09/11), weekday, month, day, watch battery %, Body Battery, steps, heart rate, calories, floors, stress or digital time.
Steps and floors run from zero to your daily goal. Heart rate runs from 40 to 180.

Always-on display: when the watch sleeps, the face draws thin outline hands and small markers on black, so it stays readable and is easy on the screen. The seconds hand shows while the watch is awake. You can turn it off.

Other settings: southern hemisphere moon (the lit side is mirrored), and the seconds hand on or off.

Nothing leaves the watch. No account, no phone app, no subscription.

Works on: fēnix 9 Pro 43mm, fēnix 9 43mm and fēnix 8 43mm.

Not affiliated with Patek Philippe or Garmin.

## What's New (optional)

1.0.1: Body Battery, stress and heart rate now come from the watch's own complications. The two 12 o'clock windows are set separately (day/month as numbers, battery %, and more). Bigger moon and date.

## Form answers

| Field | Value |
|---|---|
| Category | Watch Faces |
| Does your app collect user data? | No. Everything stays on the watch. No server, no account. |
| ANT+ profiles | No |
| Regional limits | No |
| Email address | your choice (see README note; the app has no support site) |
| Source code URL | leave blank |
| Review notification | Yes |
| App migration (new devices) | Yes |
| Monetization | No |
| Companion app | none |
| Additional hardware | none |
| Preview video | none |

Permissions shown by the store: Sensor History (used for Body Battery).

## Images (in `store/`)

| File | Size | Use |
|---|---|---|
| `icon-128.png` | 128 × 128, 24 KB | app icon |
| `cover-500x500.png` | 500 × 500, 132 KB | cover / thumbnail |
| `hero-1440x720.jpg` | 1440 × 720, 135 KB | hero banner |
| `screen-1-light.png` | 416 × 416, 87 KB | light dial, default slots |
| `screen-2-dark.png` | 416 × 416, 82 KB | dark dial, default slots |
| `screen-3-fields.png` | 416 × 416, 87 KB | heart rate, battery, digital time, date windows |
| `screen-4-always-on.png` | 416 × 416, 6 KB | always-on display |

Every image is under the store's 150 KB limit (`store/make-store-images.py` enforces it: palette PNG when
that fits, JPEG otherwise).

Screenshots come from the simulator via the `store-*` builds, which draw the dial at 92 % so the
simulator's bezel image hides nothing; on the watch the dial fills the screen.
