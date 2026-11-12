From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/7] arm64: dts: allwinner: h616: Orange Pi Zero2 fixes,
 GPU DVFS and GPU cooling
Date: Thu, 12 Nov 2026 09:22:30 +0000
Message-Id: <20261112-h616-zero2-dt-v3-0-1cd2664230c8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ7CIBQFr2JYi/lQS6sr72Fc0A+0GFsMVKI2v
 btQN42Jy0nezJtI0N7qQI6biXgdbbBuSFBsNwQ7ObSaWpWYcOCCMQa0E0zQt/aOUzVSic0eUaO
 UYEhy7l4b+1x658uXw6O5ahxzJC86G0bnX8thZHn3rx0ZBQplCUJVAgxnp7aX9rZD15Pcjnxts
 1+bJ7uuVQ0FGDxU5dqe5/kDz1R0LPoAAAA=
X-Change-ID: 20261110-h616-zero2-dt-acb4ccecaa0f
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Ryan Walklin <ryan@testtoast.com>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794475350; l=3901;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=EcorY9ABEr/4gHmXcW2+R94Df3LCsmxuz8LcRaA2fBg=;
 b=xb71hD2kQtHAi/ZM7nHrlFQfY0xwGdRpQ17jI7RajpNp0bKc0J9Fpfcamxajh6xLEJbC0SuQ4
 SCyPsDAGF/FDue34l9F+NBGMZCx29JW+YY2c2hiFauhsxf4DnIxXku4
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series collects the device tree changes we carry for the Orange
Pi Zero2 (H616):

- Patch 1 makes the H616 codec node cover the DAC RAMP register that
  the driver uses (it currently works only because ioremap() rounds up).
- Patch 2 fixes intermittent dead-RX boots of the Zero2's Ethernet by
  letting the RTL8211F add the RX delay ("rgmii-rxid"), as the Zero3
  already does.
- Patches 3 and 4 add an H616 GPU OPP table and make the Mali-G31 a
  cooling device of the GPU thermal zone, with a passive trip point.
- Patches 5 and 6 enable GPU DVFS on the Zero2. Patch 5 first raises the
  floor of the GPU supply to 900 mV, because on this board the rail is
  shared with VDD-SYS and the video engine corrupts decoded frames at
  810 mV.
- Patch 7 describes the SPI NOR supply.

Testing, on an Orange Pi Zero2 with a v7.3-based kernel carrying the
same DT content:
- RGMII: 10 of 10 cold boots with a working receive path (the problem
  showed up as intermittent dead-RX boots before); iperf3 853/873 Mbit/s
  and 86 minutes of traffic without loss.
- VDD-SYS: with the VE at 600 MHz, only 6 of 13 4K H.265 decodes were
  bit-exact with the rail at 810 mV; 3 of 3 at 890 mV and 3 of 3 at
  950 mV. With the 900 mV floor, a 70-minute decode soak (H.265 and VP9)
  had 42 of 42 runs correct.
- GPU DVFS: panfrost devfreq scales 306-600 MHz and the vdd-gpu-sys
  voltage follows the OPPs within [900, 990] mV.
- GPU cooling: the gpu-thermal zone binds the panfrost devfreq cooling
  device. The 85 C trip itself was not reached on this board (it peaked
  at about 70 C).
- SPI NOR: the "supply vcc not found, using dummy regulator" message is
  gone; the flash reads back correctly.
- Codec: analog line-out playback works.

The series is based on sunxi/dt-for-7.5. "make CHECK_DTBS=y W=1" gives
no new warnings for the H616/H618 boards. The Zero3 shares the GPU
supply design, but I have no Zero3 to test, so it is left out.

These patches were developed with Claude (Anthropic) as a
coding assistant: it investigated the problem, wrote the code and
the commit messages. I reviewed them, and they were tested on an
Orange Pi Zero2 (H616) as described above.

---
Changes in v3:
- Dropped "orangepi-zero2: Add i2c aliases": the extension connector
  is not covered by the board DT, an overlay that enables a header bus
  can add its alias (Jernej Skrabec).
- Link to v2: https://patch.msgid.link/20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com

Changes in v2:
- h616: Add GPU OPP table: use <target target max> voltage triplets
  like the H6 GPU OPP table, so that boards whose GPU supply cannot
  reach an OPP's target voltage lose that OPP instead of running it
  undervolted (found by the Sashiko AI review). No change on the
  Orange Pi Zero2 (AXP305 DCDCC at 900 to 990 mV keeps all ten OPPs).
- Link to v1: https://patch.msgid.link/20261110-h616-zero2-dt-v1-0-05506d760f21@gmail.com

---
Arun Iyengar (7):
      arm64: dts: allwinner: h616: Cover the codec RAMP register
      arm64: dts: allwinner: orangepi-zero2: Let the PHY add the RX delay
      arm64: dts: allwinner: h616: Add GPU OPP table
      arm64: dts: allwinner: h616: Throttle the GPU from the GPU thermal zone
      arm64: dts: allwinner: orangepi-zero2: Keep VDD-SYS at or above 900 mV
      arm64: dts: allwinner: orangepi-zero2: Enable GPU DVFS
      arm64: dts: allwinner: orangepi-zero2: Describe the SPI NOR supply

 .../boot/dts/allwinner/sun50i-h616-gpu-opp.dtsi    | 62 ++++++++++++++++++++++
 .../dts/allwinner/sun50i-h616-orangepi-zero2.dts   | 13 +++--
 arch/arm64/boot/dts/allwinner/sun50i-h616.dtsi     | 17 +++++-
 3 files changed, 87 insertions(+), 5 deletions(-)
---
base-commit: a7f6e476aaedba0d8ec575acaeb3257f900a592f
change-id: 20261110-h616-zero2-dt-acb4ccecaa0f

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

