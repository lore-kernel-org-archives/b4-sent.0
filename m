From: Cristian Filipescu <filipescu.cristian@gmail.com>
Subject: [PATCH v2 0/2] arm64: dts: allwinner: Support Orange Pi 3 LTS
Date: Thu, 22 Oct 2026 05:56:04 +0000
Message-Id: <20261022-sunxi-orangepi-3-lts-v2-0-70b899252c6a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHSl2WoC/yWM3Q6CMAxGX4X02iZYCFFfxXixjSo1ZJCVmSWEd
 3fVy/P9nB2Uk7DCrdkh8UdUlliBTg2EycUXo4yVgVoazi0Rao5FcEnWrYIdzpti3/krUT+4C49
 Qr2vip5Sf9v74s2b/5rCZyxbeKaOvljBZNEvMBS2E4/gCnxZUk5UAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792648566; l=4037;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=UWARrsbcfqqgmoUfwye7apXutTup2/cnkBWxxeBO1G8=;
 b=Fis/SI/NwEVhlFc/JEIH4uS2Tg4IpEa6L7GSS4krojtK6zXY72tIac9VY33JDqYQLUakPuHBD
 mf7uB3uRGEjAK/yrElPyLps0orgN6OxFJqhGscpGQQD6biyzSw/xulm
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Continue Jernej Skrabec's April 2025 Orange Pi 3 LTS series, retaining
his authorship and Rob Herring's acknowledgement of the binding patch:
https://lore.kernel.org/linux-sunxi/20250413134318.66681-1-jernej.skrabec@gmail.com/

Add the board compatible and a device tree for the Allwinner H6-based
Orange Pi 3 LTS, with 2 GiB LPDDR3, 8 GiB eMMC, Motorcomm YT8531C
Ethernet PHY, USB host ports and HDMI. The wireless module's SDIO wiring
and power supplies are described; working Wi-Fi/Bluetooth is not claimed.

Changes since v1:
- Rebase onto current mainline Linux.
- Fix oscillator naming and use CLK_OSC32K_FANOUT.
- Chain the GMAC and wireless 3.3 V regulators to their input supply.
- Keep BLDO3 always on and describe the PM-bank supply.
- Document the DCDCA/DCDCB polyphase arrangement.
- Use rgmii-id with zero MAC delays and 1950 ps PHY RX/TX delays,
  following the Ethernet discussion in the original review.
- Use green PL7 as the power LED and red PL4 as the status LED.
- Default green off and red on for Linux startup; userspace can clear
  both at its readiness milestone. U-Boot overrides its own defaults.

The device-tree hardware settings match the accompanying U-Boot series;
only include paths differ. U-Boot boot tests of the earlier red-LED
revision confirmed 2 GiB RAM, SD/eMMC enumeration, DHCP and ping.
The submitted green-LED U-Boot revision also booted the Linux test
image from SD. The corrected U-Boot handoff LED sequence has also
been confirmed on the board.

Validation:
- Compile both the new LTS DTB and the existing Orange Pi 3 DTB.
- Run dt_binding_check for arm/sunxi.yaml.
- Validate both board DTBs against the full processed schema set.
- Run checkpatch --strict, ignoring FILE_PATH_CHANGES because the new
  DTS is already covered by the Allwinner MAINTAINERS directory pattern.
- Build an Allwinner-focused arm64 diagnostic kernel with the required
  drivers built in and a separate BusyBox initramfs for RAM-only testing.

The proposed eMMC properties remain conservative. Higher-speed eMMC
modes and the earlier LED drive-strength question are not resolved by
this revision's build and schema checks.

On-board Linux testing with the diagnostic CONFIG_MODULES=y kernel
reaches the RAM shell with four CPUs and 2 GiB RAM. AXP806 regulators
initialize successfully; SD, eMMC and an SDIO card enumerate; eth0 and
USB host root hubs register. An earlier CONFIG_MODULES=n diagnostic
build failed to defer pinctrl probing and timed out accessing the PMIC.
The latest test no longer exhibits that failure.

The YT8531 PHY links at 1 Gbps/full duplex; DHCP, DNS and an IPv6
Internet ping passed (2/2 received). Two direct 8 MiB reads from each
of SD and eMMC compared identical. Two cold starts with LED, shell and
Ethernet checks were confirmed. Sustained transfer, external USB device
transfers and HDMI output remain untested.
The installed Fedora IoT deployment is untouched. The test initramfs
clears both LEDs before opening the shell. After updating the bootloader, Cristian confirmed the complete
sequence: green in main U-Boot, red at Starting kernel, both off at
the diagnostic shell.

Codex assisted with adapting the original DTS and review feedback,
preparing this cover and container build/test tooling, and analyzing
the supplied serial log. The board boot was performed by Cristian.

Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
Jernej Skrabec (2):
      dt-bindings: arm: sunxi: Add Orange Pi 3 LTS board
      arm64: dts: allwinner: h6: Add Orange Pi 3 LTS

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 .../dts/allwinner/sun50i-h6-orangepi-3-lts.dts     | 362 +++++++++++++++++++++
 3 files changed, 368 insertions(+)
---
base-commit: 4403278e4ea2f654f8130a5c03eb8b4516a0f201
change-id: 20261022-sunxi-orangepi-3-lts-43b92246a8ed

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

