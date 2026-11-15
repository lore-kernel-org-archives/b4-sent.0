From: Cristian Filipescu <filipescu.cristian@gmail.com>
Subject: [PATCH v4 0/2] arm64: dts: allwinner: Support Orange Pi 3 LTS
Date: Sun, 15 Nov 2026 23:50:52 +0000
Message-Id: <20261115-sunxi-orangepi-3-lts-v4-0-7749b448a4dd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFxF+moC/4XOzQ6CMAwH8FcxO1uDZSB48j2Mh20UqEEgGxAM4
 d3d8MLFePz349cuwpFlcuJ6WISliR13rQ/yeBCmVm1FwIXPAiNMzxEiuLGdGTobej1DDM3gQMY
 6R5SpyqgQfrW3VPK8sffHN7tRP8kMwQoTWjkC7RVTh1LD7ThDKIZmzW7o7Ht7asKA/Lk/IURwi
 XSW55igSdWteiluTqZ7iXB/ivdI+gOJPZJnJZWyvCTnTO6RdV0/GibFPiwBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794786652; l=3513;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=WV5vutgoFlQy6uYyONZ4XLW0FK70zltboXYWtatPJRY=;
 b=5SiuciC0S2s4eefcUNmzApMh/+Q35Y9p1hRymZ6jmEhMCsQ5jQ10FkFkLaQuya5+CXcsOiHEq
 d5RPcl0ddTKDcmHFStR0KLQc7QvxVnGozYZp7nx1cyKLi9wjrgAtSOn
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Continue Jernej Skrabec's April 2025 series, adding the board compatible
and device tree for the Allwinner H6-based Orange Pi 3 LTS.

Use the common Orange Pi H6 include and describe the LTS differences.
Follow the schematic's LED roles, describe the shared CPU supply on all
four cores, remove unused USB ID detection, and use generic PHY discovery
with bus-level reset. The binding patch is unchanged.

Board testing on the current v4 description verified LED names/defaults
and drive strength 10, all four CPU supply references and the shared
cpufreq policy, and BLDO2 enabled at 1.8 V. eMMC negotiated 8-bit HS200
at an actual 150 MHz with 1.8 V signaling; 768 MiB of sampled direct reads
matched across three passes, with unchanged settings and zero reported
MMC error counters. Generic PHY discovery passed five interface cycles
and three MAC rebinds both with and without temporary PHY-ID logging.
Each run obtained eight DHCP leases and 24/24 ping replies at 1 Gbps/full
duplex, with physical PHY ID and 125 MHz clock configuration read back.

The schematic trace and a 1.8 V measurement at RW1 relative to board
ground support retaining BLDO3 as the Wi-Fi I/O supply. This does not
claim functional onboard Wi-Fi support. DTB build, schema validation and
strict patch checks pass. The submitted DTS matches the tested generic
variant; diagnostic kernel instrumentation is outside the patch series.

Codex assisted with DTS updates, review analysis and build checks;
Cristian performed the board tests and voltage measurement.

---
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
 .../dts/allwinner/sun50i-h6-orangepi-3-lts.dts     | 188 +++++++++++++++++++++
 3 files changed, 194 insertions(+)
---
base-commit: 4403278e4ea2f654f8130a5c03eb8b4516a0f201
change-id: 20261022-sunxi-orangepi-3-lts-43b92246a8ed

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

