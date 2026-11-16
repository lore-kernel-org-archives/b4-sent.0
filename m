From: Cristian Filipescu <filipescu.cristian@gmail.com>
Subject: [PATCH v5 0/2] arm64: dts: allwinner: Support Orange Pi 3 LTS
Date: Mon, 16 Nov 2026 16:44:29 +0000
Message-Id: <20261116-sunxi-orangepi-3-lts-v5-0-979cf5474913@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO0y+2oC/4XOzY6CMBAH8FcxPTsbGAZoPfkexkNbioxBMC0Qj
 OHdt3UPazYxe/zPx2/mKYLz7II47J7Cu4UDj0MM5X4nbKeHiwNuYhaYYZVniBDmYWUYferdGQr
 opwBUGIVIlZauEXH17l3L64s9nX9ymM3V2SlZacLo4MBExXap1PMwr5CKqdlxmEb/eD21YEL+u
 b8gZFBnRiqFJdpKHy83zf2XHW8i3V+Kd6T6gBQRUbJ1LbV1mUv6i9AvkuflB4TSJzUpQyQ1Nc0
 7sm3bN+CxQalxAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794847469; l=4684;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=yvbbvDA0lpxvYsV9tvrk9UhEBzJNM75uNkRtwsHky1E=;
 b=pEXRpO2C8ZUCd2NuLcdZ/mwWYqmMVp+vidTtr7CVR3gtCg23IbQ8bt05ZXB51N35XDQaDV3ZZ
 n94jCQShLKhA/scD/5Y/WrM1SEQ6Ey5v5l2zjhp1nIJDFtaD8b5kZck
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Continue Jernej Skrabec's April 2025 series, adding the board compatible
and device tree for the Allwinner H6-based Orange Pi 3 LTS.

Use the common Orange Pi H6 include and describe the LTS differences.
Follow the schematic's LED roles, remove unused USB ID detection, and
use generic PHY discovery with bus-level reset. The binding patch is
unchanged apart from rebasing.

Rebase onto sunxi/dt-for-7.5 at 098728144545. Inherit the common CPU/GPU
OPP tables, CPU0 supply, regulator ramp delays and CPU maximum voltage.
Remove the LTS CPU0-CPU3 supply blocks and redundant regulator overrides;
retain the LTS CPU minimum of 800 mV. The resolved OPP tables, voltage
limits and ramp delays match the tested v4 description. The new base
also carries the H6 video-codec SRAM/IOMMU changes.

Hardware results reported for v4 remain historical: LED names/defaults
and drive strength 10, shared cpufreq policy, BLDO2 enabled at 1.8 V,
768 MiB of matching eMMC HS200 reads at 150 MHz/8-bit/1.8 V with zero
reported MMC errors, and generic PHY discovery passing five interface
cycles and three MAC rebinds both with and without PHY-ID logging.
Each Ethernet run obtained eight DHCP leases and 24/24 ping replies at
1 Gbps/full duplex with PHY ID and 125 MHz clock configuration read back.
The rebased v5 description has not been boot-tested.

Following review, Cristian measured 1.8 V directly at U60/AW859A pin 22
(VDDIO) relative to board ground. The earlier connection trace was from
the schematic; the module-pin result is separate from the earlier RW1
reading. It is consistent with retaining BLDO3 as the I/O supply.
Functional onboard Wi-Fi support is not claimed.

The LTS, Orange Pi 3, Lite2 and One Plus DTBs build with W=1 and pass
validation against freshly generated schemas. The board binding and
strict patch checks pass. Diagnostic kernel instrumentation is outside
the patch series.

Codex assisted with DTS updates, review analysis and build checks;
Cristian performed the v4 board tests and the direct VDDIO measurement.

---
Changes in v5:
- Rebase onto the latest sunxi/dt-for-7.5 (098728144545).
- Inherit CPU/GPU OPP tables and CPU supply from the common include;
  remove the board-local CPU0-CPU3 supply declarations.
- Inherit regulator ramp delays and the CPU maximum voltage; retain
  the existing LTS CPU minimum of 800 mV.
- Keep any shared all-core CPU-supply cleanup outside this board addition.
- Report the requested direct U60 pin-22 VDDIO measurement of 1.8 V;
  retain the existing BLDO3 assignment.
- Distinguish v4 board results from v5 static validation.
- Link to v4: https://lore.kernel.org/all/20261115-sunxi-orangepi-3-lts-v4-0-7749b448a4dd@gmail.com/

Changes in v4:
- Base the LTS description on sun50i-h6-orangepi.dtsi.
- Inherit red PL4 as power/on and green PL7 as status/off, keeping the
  existing H6 labels and drive strength 10.
- Describe the shared CPU supply on all four cores.
- Delete inherited USB ID detection for the fixed host-mode controller.
- Drop the explicit PHY ID after generic discovery passes interface and
  MAC rebind tests with and without temporary PHY-ID logging.
- Inherit BLDO2's common always-on policy.
- Keep common regulator/clock names; defer naming cleanups.
- Update the validation results and explanations in the review replies.
- Link to v3: https://lore.kernel.org/all/20261026-sunxi-orangepi-3-lts-v3-0-98fef4f75184@gmail.com/

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
 .../dts/allwinner/sun50i-h6-orangepi-3-lts.dts     | 164 +++++++++++++++++++++
 3 files changed, 170 insertions(+)
---
base-commit: 09872814454580dad9f04fb194a7befe0fd6e94f
change-id: 20261022-sunxi-orangepi-3-lts-43b92246a8ed

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

