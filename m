From: Andrei Aleksandrov <aladex@gmail.com>
Subject: [PATCH RFC 0/2] ALSA: usb-audio: Make the EPOS GSX 1000 v2 volume
 ring work
Date: Fri, 27 Nov 2026 08:15:20 +0100
Message-Id: <20261127-gsx1000-v1-0-833554c37b82@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNz3fTiCkMDAwNdS1ODNCNLc3MTAwsDJaDqgqLUtMwKsEnRSkFuzkq
 xEMHi0qSs1OQSkBlKtbUAxIqMdnAAAAA=
X-Change-ID: 20261127-gsx1000-950f29774080
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-input@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Andrei Aleksandrov <aladex@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795763720; l=2896;
 i=aladex@gmail.com; s=20261127; h=from:subject:message-id;
 bh=Cx5E16DVxiKC2W4AXUGiE4DSUnwoqavuCDkkSrkCAGU=;
 b=/FLIARca831KI99M2Hcc6myUHvdtGx/mI4TXGlV5zWmzSOlqmag+JNTZkIRBB4qduNEd8uorU
 Pg224/1KH9rDDKSEzgLOjFosffB5ildc4BkuL6UEUahhlnhf56BPzz/
X-Developer-Key: i=aladex@gmail.com; a=ed25519;
 pk=BRFQEVGQ1X027TItMW+SIsAtbYscopzlk1EJT8Girkg=
X-Endpoint-Received: by B4 Relay for aladex@gmail.com/20261127 with auth_id=1663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The volume ring of the EPOS / Sennheiser GSX 1000 v2 has never worked on
Linux: turning it makes the volume oscillate or run down, and the usual
workaround is to disable it with a hwdb rule [1][2][3]. This series makes
it behave as on Windows, based on USB captures of the Windows inbox
driver (usbaudio.sys + HID, there is no vendor driver):

- the ring sends HID Vol+/Vol- until the volume the host writes to FU 12
  matches the ring position, and compares it with 1/256 dB precision;
- Windows writes fractional dB values from its 0..100 % scale to
  channels 1 and 2 of FU 12, in 2 % steps per ring detent.

Patch 1 replaces the 1 dB FU 12 volume with a 0..100 control that writes
the exact values measured from Windows. Patch 2 answers the ring's
Vol+/Vol- in the driver with the Windows step.

This is an RFC because of two design choices I would like your opinion
on:

1. The new control has no dB TLV, on purpose: with a TLV, PipeWire and
   PulseAudio map their volume through the dB curve, and the number on
   the device display no longer matches the desktop percent. Without it
   they map linearly onto the 101 steps and the display matches, as on
   Windows. Would you prefer a TLV (e.g. a DB_RANGE over the table)
   instead, accepting the display mismatch?

2. Patch 2 registers an input handler with a .filter callback that
   swallows KEY_VOLUMEUP/KEY_VOLUMEDOWN from this card's own HID
   interface. Subscribing to HID input from mixer_quirks.c has a
   precedent (the DualSense jack detection), filtering does not. Is this
   acceptable in snd-usb-audio, should it be optional (a module
   parameter), or would you rather see it done elsewhere?

Only 1395:00b1 is enabled. The GSX 1000 v1 (005e, 00a0) and GSX 1200
(005f, 00a1) are likely similar, but I have no captures of them.

The captures, their decoding and a DKMS package of the same code (in
use on 7.3) are at https://github.com/Aladex/epos-gsx.

Disclosure: the reverse engineering and these patches were prepared with
the help of an AI coding assistant. I reviewed the code, and I tested it
on my own device; the captures are from my hardware.

[1] https://bugs.launchpad.net/bugs/1821496
[2] https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/3714
[3] https://github.com/evilphish/sennheiser-gsx-1000

Signed-off-by: Andrei Aleksandrov <aladex@gmail.com>
---
Andrei Aleksandrov (2):
      ALSA: usb-audio: Add Windows volume scale quirk for EPOS GSX 1000 v2
      ALSA: usb-audio: Handle the EPOS GSX 1000 v2 volume ring in the driver

 sound/usb/mixer_maps.c   |  11 ++
 sound/usb/mixer_quirks.c | 343 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 354 insertions(+)
---
base-commit: 486060b97284c95384744f030706f89e1980a46e
change-id: 20261127-gsx1000-950f29774080

Best regards,
--  
Andrei Aleksandrov <aladex@gmail.com>

