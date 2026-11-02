From: Joseph Telaak <joseph@telaak.dev>
Subject: [PATCH 00/10] leds: ktd202x: Add Etek ET6326, hardware breathing
 and fixes
Date: Sun, 01 Nov 2026 21:12:24 -0500
Message-Id: <20261101-ktd202x-et6326-v1-0-eb51eddad08c@telaak.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMSw5AMBSF4a3IHWvSB5XYihjQXlwSpC1pIvaum
 J1vcP4LPDpCD3V2gcOTPG1rgsgzMFO3jsjIJoPkUgvBBVuCTTsyDFpJzSqFVvFCm1IVkE67w4H
 iF2za3/7oZzThrcB9P/LXpm5yAAAA
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
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793585579; l=3791;
 i=joseph@telaak.dev; s=20261102; h=from:subject:message-id;
 bh=5szKME+RGUgTgRCPG18UXULk6pa/gRroJHRqBmosyr0=;
 b=INmn57vmR2Y+hFB0wQpY4QXWmisJAw7xElGPF+GR1w2yRrNievb3OzDiT6s7gU0SmNV5OHd8m
 or7ArLy4GBTBSabguA3yK+Ec8Cyr84LUTdRU9pBITbFPDZWGPC3vVnV
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=OmwSusdK4grZpiuZVfCZAvYyqz9FBkNemsV1EnHyVr4=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261102 with auth_id=1382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Etek ET6326 drives the status LED of the GL.iNet GL-SFT1200 (Opal)
router. It is register compatible with the Kinetic KTD2026, except for
the flash period: Reg1 = n is (n + 1) * 128 ms on the ET6326 and
256 ms + n * 128 ms on the KTD202x. Patches 5 and 6 add it with the
KTD2026 as fallback, so older kernels drive it with slightly off blinks.

Patches 1 to 4 fix bugs that have been there since the driver was
added, and come first so they can be applied on their own:
- a blink shorter than 256 ms became a 16 s blink on 32 bit
- with fewer LEDs in the DT than channels, as on this board, the driver
  read past the end of its LED array
- a blink with a very short on time was programmed as never on
- delays from the timer trigger that add up to 2^32 (or 2^64) divided
  by zero, and long blinks overflowed the on time on 32 bit

Patch 7 lets the pattern trigger's hw_pattern use the chip's rise and
fall ramps, so a breathing LED needs no I2C traffic. Patch 8 honors
led-max-microamp on single color LEDs: the GL-SFT1200 drives three LEDs
in parallel on each channel at 1.375 mA, and the driver's full
brightness is 24 mA. Patch 9 fails the probe when nothing answers at the
address. Patch 10 stops a second blinking LED from silently retiming the
first: it shares the flash timer only with the same timing, and
otherwise blinks in software. The second PWM timer is no help, since in
the timer slot the driver uses it repeats the first.

ET6326 datasheet:
https://www.etekmicro.com/wp-content/uploads/datasheets/ET6326_datasheet.pdf

Tested on a GL-SFT1200 (SF19A2890, MIPS32) with OpenWrt and Linux
6.18.55, with the two LEDs of the board (blue and white, three LEDs in
parallel on each channel, led-max-microamp = <1375>):
- brightness 1 to 11 (max_brightness 11 from led-max-microamp), and
  waking the chip from sleep
- the timer trigger from 1/1 ms to 500/500 ms; a camera measured a
  0.916 s period for 896 ms, the same 2.2 % slow oscillator as with the
  stock firmware, so the ET6326 period encoding is the one used here
- breathing through hw_pattern, written right after selecting the
  pattern trigger
- invalid patterns and finite repeats rejected
- a second LED blinking at another rate falls back to software and
  leaves the first one alone
- 240 writes to one LED while the other stayed lit, module unload and
  reload, and a reboot while blinking
The bug fixes were also checked with a simulated chip under ASan and
UBSan, and the series builds with W=1 on x86_64, i386, MIPS and arm64.

---
Joseph Telaak (10):
      leds: rgb: ktd202x: Fix the flash period of short blinks on 32 bit
      leds: rgb: ktd202x: Fix an out-of-bounds read with unused channels
      leds: rgb: ktd202x: Never program an on time of zero
      leds: rgb: ktd202x: Fix a division by zero with long blinks
      dt-bindings: leds: kinetic,ktd202x: Add Etek ET6326
      leds: rgb: ktd202x: Add Etek ET6326 support
      leds: rgb: ktd202x: Add hardware pattern support
      leds: rgb: ktd202x: Limit the LED current to led-max-microamp
      leds: rgb: ktd202x: Fail the probe when the chip does not answer
      leds: rgb: ktd202x: Don't let a blinking LED retime another one

 .../devicetree/bindings/leds/kinetic,ktd202x.yaml  |  15 +-
 Documentation/leds/index.rst                       |   1 +
 Documentation/leds/leds-ktd202x.rst                |  48 +++
 drivers/leds/rgb/Kconfig                           |   3 +-
 drivers/leds/rgb/leds-ktd202x.c                    | 423 +++++++++++++++++----
 5 files changed, 419 insertions(+), 71 deletions(-)
---
base-commit: 59cf91cf87abb67a49b1bb7b9d3b06486abde8cf
change-id: 20261101-ktd202x-et6326-73ed3046c534

Best regards,
--  
Joseph Telaak <joseph@telaak.dev>

