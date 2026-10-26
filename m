From: Cristian Filipescu <filipescu.cristian@gmail.com>
Subject: [PATCH v3 0/2] arm64: dts: allwinner: Support Orange Pi 3 LTS
Date: Mon, 26 Oct 2026 23:30:59 +0000
Message-Id: <20261026-sunxi-orangepi-3-lts-v3-0-98fef4f75184@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALPi32oC/4WOQRKCMAxFr8J0bRwMiODKezgs2lIhDrRMAwwOw
 91t8QAu3//JSzbBxpNhcU824c1CTM4GyE6J0J20rQFqAgtMsbikiMCzXQmcj91IkEE/MeSZqhD
 zQpamEWF19OZF66F91j/mWb2NnqIrTijJBlSw6C5GPdl5hRjGsiOenP8cTy0YJX/uLwgp3FJVV
 hVeURfy0Q6S+rN2g6j3ff8C0SUoP+cAAAA=
X-Change-ID: 20261022-sunxi-orangepi-3-lts-43b92246a8ed
To: linux-sunxi@lists.linux.dev, devicetree@vger.kernel.org, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Andre Przywara <andre.przywara@arm.com>, linux-kernel@vger.kernel.org, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793057459; l=1992;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=ssdCd+cOb3vtsGK2tRgFxcvft6R9+5/9qtV6Fbja4Yg=;
 b=1vCFUDdeBnX3cdyq4w/VMNM8FHwVt4nneYPP6UQr+YeFjWhX4ilKTbVh8tBWcfLau/2MnN2YN
 I//RPwFuqAFDGe6oRRlVHkYTp/Ryr8qdYsa/lzxqWCCsq9pbXb85ZqV
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Continue Jernej Skrabec's April 2025 series, adding the board compatible
and device tree for the Allwinner H6-based Orange Pi 3 LTS.

Board testing passed SD/eMMC reads, both LEDs at drive strength 10,
and five Ethernet interface cycles plus three MAC driver rebinds.
Each network cycle reached 1 Gbps/full duplex, obtained DHCP and passed
ping; PHY ID and 125 MHz clock-output configuration were read back.
eMMC DDR52 at 50 MHz and HS200 at 150 MHz each passed 768 MiB of direct
reads and 256 MiB of patterned writes with verified readbacks and data
restoration. All reported MMC error counters were zero. Both board DTBs
compile and pass schema checks.

Codex assisted with DTS updates, review analysis and build checks;
Cristian performed the board tests.

---
Changes in v3:
- Keep green as power and red as status, matching Armbian LTS roles;
  default green on and red off without a boot-stage sequence.
- Select drive strength 10 on PL4 and PL7 with per-LED pinctrl states.
- Move PHY reset to the MDIO bus, before discovery and outside detach.
- Specify the YT8531C PHY ID; MAC rebind fails with early autodetection.
- Enable 1.8 V eMMC DDR52 and HS200 after board testing; retain the
  existing H6 maximum frequency of 150 MHz.
- Shorten the descriptions and update validation status.
- Link to v2: https://lore.kernel.org/all/20261022-sunxi-orangepi-3-lts-v2-0-70b899252c6a@gmail.com/

---
Jernej Skrabec (2):
      dt-bindings: arm: sunxi: Add Orange Pi 3 LTS board
      arm64: dts: allwinner: h6: Add Orange Pi 3 LTS

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 .../dts/allwinner/sun50i-h6-orangepi-3-lts.dts     | 379 +++++++++++++++++++++
 3 files changed, 385 insertions(+)
---
base-commit: 4403278e4ea2f654f8130a5c03eb8b4516a0f201
change-id: 20261022-sunxi-orangepi-3-lts-43b92246a8ed

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

