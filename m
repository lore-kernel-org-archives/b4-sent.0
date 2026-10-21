From: Cristian Filipescu <filipescu.cristian@gmail.com>
Subject: [PATCH 0/2] sunxi: Add Orange Pi 3 LTS support
Date: Wed, 21 Oct 2026 21:13:01 +0000
Message-Id: <20261021-sunxi-orangepi-3-lts-v1-0-19a3df928d8e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN0q2WoC/yWMTQqDMBBGryKz7oBJIIJXKV0kcVJHbJSMiiDev
 Um7fN/Pu0AoMwn0zQWZDhZeUgH1aCCMLr0JeSgMutVWtVqh7OlkXHLtVkaD8yaoo+vsQDYaq6B
 c10yRz5/2+fqz7H6isFVXXXgnhL5Ywlijj+ME9/0FtVd6jo8AAAA=
X-Change-ID: 20261021-sunxi-orangepi-3-lts-2fa76de6f361
To: u-boot@lists.u-boot-project.org
Cc: Andre Przywara <andre.przywara@arm.com>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 Cristian Filipescu <filipescu.cristian@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792617188; l=3002;
 i=filipescu.cristian@gmail.com; s=uboot-20261021; h=from:subject:message-id;
 bh=+WN3IsTxt3TITUp03kQY8oGQ8ChFZHv0M0LuxDXupvM=;
 b=EJ6QK3dFlAlAvxJTL6Ecrwc2ZO1D0J0YF2JqFbyhOuIK2QEnpCgY1OV3H1VcbgeofKEG9vJAy
 1AJWj4McAWBATyG6nyuUR5BGXWqUFagBibBufw0+pFcoIVnCT305o+C
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
  TF-A v2.13.0 (sun50i_h6, DEBUG=1). The existing orangepi_3_defconfig
  built in the earlier validation and its sources are unchanged.
- Verify the LTS DT model, Ethernet configuration and final combined FIT.
- Match the new defconfig to savedefconfig output.
- Check both patches with checkpatch.pl --strict, excluding only the
  FILE_PATH_CHANGES warning: board/sunxi/MAINTAINERS is updated, but
  checkpatch recognises only a top-level MAINTAINERS change.

The current source differs from the tested c8f95275fc8f revision only in
LED settings: select green PL7 for the power indicator and SPL status LED,
and describe red PL4 as the status LED. The updated LED indication has
not yet been checked on the board.

On-board testing of the pre-LED-change U-Boot 2026.10-gc8f95275fc8f:
- Reaches the console and reports 2 GiB RAM.
- Enumerates SD at 50 MHz/4-bit and eMMC at 52 MHz/8-bit.
- Obtains a DHCP lease and pings two LAN hosts successfully. The control
  device tree confirms phy-mode = "rgmii-id".
- Enumerates EHCI, OHCI and XHCI root hubs. External USB peripherals have
  not been tested.

Repeated cold starts and an operating-system boot have not been tested.
The local test builds omit optional Crust firmware; suspend is not tested.

Signed-off-by: Cristian Filipescu <filipescu.cristian@gmail.com>
---
Cristian Filipescu (1):
      sunxi: Add Orange Pi 3 LTS defconfig

Jernej Skrabec (1):
      arm: dts: sunxi: Add Orange Pi 3 LTS device tree

 arch/arm/dts/Makefile                     |   1 +
 arch/arm/dts/sun50i-h6-orangepi-3-lts.dts | 361 ++++++++++++++++++++++++++++++
 board/sunxi/MAINTAINERS                   |   6 +
 configs/orangepi_3_lts_defconfig          |  19 ++
 4 files changed, 387 insertions(+)
---
base-commit: 62c9805d8d57cad407f0295879cc9a6182da464a
change-id: 20261021-sunxi-orangepi-3-lts-2fa76de6f361

Best regards,
--  
Cristian Filipescu <filipescu.cristian@gmail.com>

