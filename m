From: Cristian Filipescu <filipescu.cristian@gmail.com>
Subject: [PATCH v2 0/2] sunxi: Add Orange Pi 3 LTS support
Date: Thu, 22 Oct 2026 05:55:00 +0000
Message-Id: <20261022-sunxi-orangepi-3-lts-v2-0-46b9df5f9e43@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADSl2WoC/4WOQQ6DIBBFr9Kw7jSCCdWueo/GBcKg0ygYUGNjv
 HvBHqDL92f+m9lZxEAY2eOys4ArRfIugbhemO6V6xDIJGaiEJIXgkNc3EbgQ55NBCUMcwRh1V0
 alLaUnKXqFNDSdmpfzY/j0r5Rz9mVN1oVEdpk0X2ORkUuxz3F2YfP+c7Kc/3P5ZVDAbxWpbG1q
 EyFzy65hpv2I2uO4/gCYkmjFuEAAAA=
X-Change-ID: 20261021-sunxi-orangepi-3-lts-2fa76de6f361
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792648514; l=4940;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=w2wBOHmwb3OIqFFw3J6DNE2wEyLk5UTaOSqUVQp8+GA=;
 b=wGISQq+6rNX0FPfyHSnse6FVNxRgTsNExFZeGT2iKSRgr+quB6Wgw6KqgqujntnCItsDGIHjx
 xDL86WkT/8xCVlpoILHwDQ7wiH4hry7WLh51CQbZHCTnZpiarVfuj+9
X-Developer-Key: i=filipescu.cristian@gmail.com; a=ed25519;
 pk=o7Ui0tU3x+X/6Pq6PZHmd2KFtOdPWttoPuNFOvdD8t0=
X-Endpoint-Received: by B4 Relay for filipescu.cristian@gmail.com/uboot-20261021 with auth_id=1255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a device tree and a separate defconfig for the Orange Pi 3 LTS. The
LTS has an H6, 2 GiB LPDDR3, 8 GiB eMMC and a Motorcomm YT8531C Ethernet
PHY, with power and reset wiring different from the original Orange Pi 3.

The device tree is based on Jernej Skrabec's Linux submission:
https://lore.kernel.org/linux-sunxi/20250413134318.66681-3-jernej.skrabec@gmail.com/

It lives under arch/arm/dts until the board description is merged into
Linux and reaches dts/upstream. The current dts/upstream H6 SoC and OPP
includes are reused. The original authorship and sign-off are retained.

Clock naming, regulator supply chaining and BLDO3 always-on corrections
from the earlier review are included. Ethernet uses the Motorcomm driver
with rgmii-id, zero MAC delays and explicit 1950 ps RX/TX PHY delays, as
proposed during the Linux review. This configuration has been tested on
the board with DHCP and ICMP.

Validation (including the earlier board build):
- Cross-build the revised orangepi_3_lts_defconfig with GCC 14.2.0 and
  TF-A v2.13.0 (sun50i_h6, DEBUG=1). Cross-build the original
  orangepi_3_defconfig too; its handoff hook remains an empty return.
- Verify the LTS DT model, Ethernet configuration and final combined FIT.
- Match the new defconfig to savedefconfig output.
- Check both patches with checkpatch.pl --strict, excluding only the
  FILE_PATH_CHANGES warning: board/sunxi/MAINTAINERS is updated, but
  checkpatch recognises only a top-level MAINTAINERS change.

The GPIO LEDs are enabled in main U-Boot, with green PL7 on and red
PL4 off. The early SPL LED is disabled. At the OS handoff immediately
after "Starting kernel ...", the LTS-specific board_quiesce_devices()
hook switches green off and red on. Linux's LED defaults retain those
states; diagnostic userspace clears both before starting the shell.
Cristian confirmed this sequence on the corrected 60d788d7056c build:
green in main U-Boot, red at the kernel handoff, both off in the shell.

On-board testing of the pre-LED-change U-Boot 2026.10-gc8f95275fc8f:
- Reaches the console and reports 2 GiB RAM.
- Enumerates SD at 50 MHz/4-bit and eMMC at 52 MHz/8-bit.
- Obtains a DHCP lease and pings two LAN hosts successfully. The control
  device tree confirms phy-mode = "rgmii-id".
- Enumerates EHCI, OHCI and XHCI root hubs. External USB peripherals have
  not been tested.

The submitted v1 (11d60b7149e6) also loaded a mainline Linux Image, DTB
and initramfs from SD and reached a RAM shell with four CPUs and 2 GiB
RAM. Its test-kernel configuration caused a PMIC I2C failure; Linux
peripheral validation remained pending in that first test.

The v2 build (f5a667df5ada) now boots Linux with CONFIG_MODULES=y into
the RAM shell. Linux initializes the AXP806, enumerates SD and eMMC,
registers eth0 and all USB host root hubs. The YT8531 PHY links at
1 Gbps/full duplex; DHCP, DNS and an IPv6 Internet ping passed on that
build. Two direct 8 MiB reads from each of SD and eMMC compared
identical under Linux. Two cold starts with LED, shell and Ethernet
checks were confirmed on the final build. Both LEDs were confirmed off
in the diagnostic shell. Sustained transfer, external USB peripherals
and HDMI remain untested.
The local test builds omit optional Crust firmware; suspend is not tested.

Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
Changes in v2:
- Enable GPIO LEDs in main U-Boot; drop early SPL status activation.
- Add board-specific U-Boot DT overrides: green on, red off.
- Set shared Linux defaults to retain green off and red on.
- Switch green off and red on in the LTS OS handoff hook at Starting kernel.
- Retain the original two-patch DTS/defconfig series structure.
- Link to v1: https://patch.msgid.link/20261021-sunxi-orangepi-3-lts-v1-0-19a3df928d8e@gmail.com

To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>
Cc: Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Cristian Filipescu <filipescu.cristian@gmail.com>
Cc: Andre Przywara <andre.przywara@arm.com>
Cc: Hans de Goede <hdegoede@redhat.com>
Cc: Jernej Skrabec <jernej.skrabec@gmail.com>

---
Cristian Filipescu (1):
      sunxi: Add Orange Pi 3 LTS defconfig

Jernej Skrabec (1):
      arm: dts: sunxi: Add Orange Pi 3 LTS device tree

 arch/arm/dts/Makefile                             |   1 +
 arch/arm/dts/sun50i-h6-orangepi-3-lts-u-boot.dtsi |  11 +
 arch/arm/dts/sun50i-h6-orangepi-3-lts.dts         | 362 ++++++++++++++++++++++
 board/sunxi/MAINTAINERS                           |   7 +
 board/sunxi/board.c                               |  19 ++
 configs/orangepi_3_lts_defconfig                  |  19 ++
 6 files changed, 419 insertions(+)
---
base-commit: 62c9805d8d57cad407f0295879cc9a6182da464a
change-id: 20261021-sunxi-orangepi-3-lts-2fa76de6f361

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

