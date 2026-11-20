From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH v3 00/11] leds: ktd202x: Add Etek ET6326, hardware
 breathing and fixes
Date: Thu, 19 Nov 2026 19:07:22 -0500
Message-Id: <20261119-ktd202x-et6326-v3-0-98b836b1cddc@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADuP/2oC/3WNyw7CIBBFf6VhLYZHoY+V/2FcUBgt1rQGkNQ0/
 XehbjTG3ZzknjML8uAseNQWC3IQrbfTmIDvCqR7NV4AW5MYMcIkpYTiIZh0zxiC5EziioPhpJR
 a8BIl6e7gbOcteDy92T+6K+iQK3nRWx8m99w+Rpp3f+ORYoKhExSMUYbU+hDgptSwNxBRrkf26
 Tc/Pku+kNBUmjEpRf3lr+v6AiwAy9P/AAAA
X-Change-ID: 20261101-ktd202x-et6326-73ed3046c534
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795133254; l=7350;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=Xdl7JhCrzMFcD+Yx/GVwMVIDBXAjGW7X5Emk10IWF78=;
 b=s2Wc4yDz3tHq5DaZYQeN6+q7pyyv3VEQ8qUcMoBG/ek1GMSu/grNuQohPzmrhALdiMAd2pUHF
 aJl6HX7KveTDEi0kFAM+GDxAsT0auIeENsyPvc3iFRUVnZxqlwGa09h
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Etek ET6326 drives the status LED of the GL.iNet GL-SFT1200 (Opal)
router. It is register compatible with the Kinetic KTD2026, except for
the flash period: Reg1 = n is (n + 1) * 128 ms on the ET6326 and
256 ms + n * 128 ms on the KTD202x. Patches 6 and 7 add it with the
KTD2026 as fallback, so older kernels drive it with slightly off blinks.

Patches 1 to 5 fix bugs that have been there since the driver was
added, and come first so they can be applied on their own:
- a blink shorter than 256 ms became a 16 s blink on 32 bit
- with fewer LEDs in the DT than channels, as on this board, the driver
  read past the end of its LED array
- a blink with a very short on time was programmed as never on
- delays from the timer trigger that add up to 2^32 (or 2^64) divided
  by zero, and long blinks overflowed the on time on 32 bit
- a blinking multicolor LED also lit its colors at brightness 0

Patch 8 lets the pattern trigger's hw_pattern use the chip's rise and
fall ramps, so a breathing LED needs no I2C traffic. Patch 9 honors
led-max-microamp on single color LEDs: the GL-SFT1200 drives three LEDs
in parallel on each channel at 1.375 mA, and the driver's full
brightness is 24 mA. Patch 10 fails the probe when nothing answers at
the address. Patch 11 stops a second blinking LED from silently
retiming the first: it shares the flash timer only with the same
timing, and otherwise blinks in software. The second PWM timer is no
help, since in the timer slot the driver uses it repeats the first.

ET6326 datasheet:
https://www.etekmicro.com/wp-content/uploads/datasheets/ET6326_datasheet.pdf

Tested on a GL-SFT1200 (SF19A2890, MIPS32) with OpenWrt and Linux
6.18.60, with the two LEDs of the board (blue and white, three LEDs in
parallel on each channel, led-max-microamp = <1375>):
- brightness 1 to 11 (max_brightness 11 from led-max-microamp), and
  waking the chip from sleep
- the timer trigger from 1/1 ms to 500/500 ms; a camera measured a
  0.917 s period for 896 ms, the same 2.2 % slow oscillator as with the
  stock firmware, so the ET6326 period encoding is the one used here
- a 1/200 ms blink, which keeps blinking after a new delay_off, and
  delays that add up to 2^32 ms
- a second LED blinking at another rate falls back to software and
  leaves the first one alone; with the same delays it shares the timer
  in step with the first; a LED that blinks in software takes the timer
  over at its own brightness once it is free
- the timer programmed again after the chip slept
- breathing through hw_pattern, written right after selecting the
  pattern trigger
- invalid patterns and finite repeats rejected
- the same pattern on both LEDs shares the timer, and a pattern that
  cannot get the timer leaves its LED off
- 240 writes to one LED while the other stayed lit, module unload and
  reload, and a reboot while blinking
v3 was run again on a second GL-SFT1200 with Linux 6.18.55: the
current limit and brightness, the timer trigger, a second LED refused
the timer or sharing it, a blink started from off, and breathing, with
the ramps cleared by the next blink.
The bug fixes were also checked with a simulated chip under ASan and
UBSan, and the series builds with W=1 on x86_64, i386, MIPS and arm64.

---
Changes in v3:
- Patch 2: a blank line between the number of LEDs and the allocation
  (Lee).
- Patch 3: name the shortest on time KTD202X_FLASH_ON_MIN (Lee).
- Patches 5, 8 and 11: a blank line before the colors at brightness 0
  are skipped (Lee).
- Patch 7 (Lee):
  - drop the datasheet URL from the file header; it stays as a Link: in
    the commit message
  - call the per chip data caps, and give the flash period limits named
    defines instead of comments about the period register
  - chip->num_leds stays next to caps->num_leds, as __counted_by() needs
    the count in struct ktd202x itself
- Patch 8 (Lee): KTD202X_RAMP_TFALL_SHIFT, named rise, high, fall and
  low times, loop counters declared in the for, a mutex guard instead of
  goto, and lines joined where they fit in 100 columns.
- Patch 11 (Sashiko):
  - tell that a LED is off from the brightness it is given, not from its
    colors, which can all round down to 0 when a multicolor LED is
    dimmed
  - in blink, read cdev->brightness once and always set it under the
    mutex before the timer, as the LED core may have changed it without
    applying it yet
  - mutex guards instead of goto in blink and hw_pattern (Lee)
- Patches 2, 3, 5, 7 and 8 have no functional change.
- Link to v2: https://patch.msgid.link/20261109-ktd202x-et6326-v2-0-56e97c226658@telaak.dev

Changes in v2:
- New patch 5: a blinking multicolor LED keeps its colors at brightness
  0 off. The bug is older than the series.
- Patch 6: add Krzysztof's Ack.
- Patch 7: report delay_on rounded to the nearest ms and at least 1 ms.
  On the 128 ms ET6326 period a short on time read back as 0 ms, and the
  timer trigger's next delay_off write then turned the LED off.
- Patch 8:
  - skip the colors at brightness 0, and build the channel list under
    the mutex
  - use GPL-2.0-only, not the deprecated GPL-2.0 SPDX identifier, in the
    new document
- Patch 10: the KTD2026/7 does not ACK the byte that resets it, so v1
  failed the probe on every KTD2026/7. Ignore that write again, and fail
  the probe when the write that puts the chip to sleep fails.
- Patch 11:
  - write the timer registers whenever no other LED uses the timer, so
    they are set again after the chip lost power, and release the timer
    when the write fails
  - hold the chip mutex from the brightness to the timer in blink and
    hw_pattern, and track the timer from the brightness being set, not
    cdev->brightness
  - blink at blink_brightness, not max_brightness
  - check the timer before a pattern touches the LED, and leave the LED
    as it was on -EBUSY
- Link to v1: https://lore.kernel.org/r/20261101-ktd202x-et6326-v1-0-eb51eddad08c@telaak.dev

---
Joseph Telaak (11):
      leds: rgb: ktd202x: Fix the flash period of short blinks on 32 bit
      leds: rgb: ktd202x: Fix an out-of-bounds read with unused channels
      leds: rgb: ktd202x: Never program an on time of zero
      leds: rgb: ktd202x: Fix a division by zero with long blinks
      leds: rgb: ktd202x: Keep the unlit colors of a blinking LED off
      dt-bindings: leds: kinetic,ktd202x: Add Etek ET6326
      leds: rgb: ktd202x: Add Etek ET6326 support
      leds: rgb: ktd202x: Add hardware pattern support
      leds: rgb: ktd202x: Limit the LED current to led-max-microamp
      leds: rgb: ktd202x: Fail the probe when the chip does not answer
      leds: rgb: ktd202x: Don't let a blinking LED retime another one

 .../devicetree/bindings/leds/kinetic,ktd202x.yaml  |  15 +-
 Documentation/leds/index.rst                       |   1 +
 Documentation/leds/leds-ktd202x.rst                |  51 ++
 drivers/leds/rgb/Kconfig                           |   3 +-
 drivers/leds/rgb/leds-ktd202x.c                    | 566 +++++++++++++++++----
 5 files changed, 534 insertions(+), 102 deletions(-)
---
base-commit: 59cf91cf87abb67a49b1bb7b9d3b06486abde8cf
change-id: 20261101-ktd202x-et6326-73ed3046c534

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

