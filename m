From: Dinesh kumar v <dinesh.v@adlinktech.com>
Subject: [PATCH 0/4] Add ADLINK LEC-iMX95 board support
Date: Mon, 28 Sep 2026 13:08:56 +0530
Message-Id: <20260928-lec-imx95-v1-v1-0-9e0c9b94ccbe@adlinktech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJAZumoC/x2MQQqAIBAAvyJ7bkGFLPtKdAjbaqEsFEQQ/550G
 ZjDTIFIgSnCJAoEShz58U1UJ8Cdqz8IeWsOWmojrR7xIod8Z9tjUkh6MKbBSuOgJW+gnfO/m5d
 aPwL/BxleAAAA
X-Change-ID: 20260928-lec-imx95-v1-e2766e27906c
To: "NXP i.MX U-Boot Team" <uboot-imx@nxp.com>, 
 Tanmay Kathpalia <tanmay.kathpalia@altera.com>, 
 u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Stefano Babic <sbabic@nabladev.com>, Fabio Estevam <festevam@gmail.com>, 
 Peng Fan <peng.fan@nxp.com>, Jaehoon Chung <jh80.chung@samsung.com>, 
 Alice Guo <alice.guo@nxp.com>, Primoz Fiser <primoz.fiser@norik.com>, 
 Johan Jonker <jbx6244@gmail.com>, Simona Toaca <simona.toaca@nxp.com>, 
 Francesco Dolcini <francesco.dolcini@toradex.com>, 
 Dinesh kumar v <dinesh.v@adlinktech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790581138; l=2135;
 i=dinesh.v@adlinktech.com; s=20260928; h=from:subject:message-id;
 bh=zL1J8Gvo7KX/aNNnFW41u/vTMLuwQP0C9AtPnuvE9R0=;
 b=l1U9FVvhr/rJRkehtdvlEN2+Jmb4DC0zf64d/3U1grx7juh/Z+NmLH3V10Je71ZDGQj3F3M2P
 xJQk3OxKuWyCm5rkXsfcrUFQieolxmxB3e63tvNfs5tOea0hjXMRAqW
X-Developer-Key: i=dinesh.v@adlinktech.com; a=ed25519;
 pk=2+xm2aDQjQT68aPFzfLMgdZrQGpCMUU3Qp1CwWoRlus=
X-Endpoint-Received: by B4 Relay for dinesh.v@adlinktech.com/20260928 with auth_id=1074
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds U-Boot support for the ADLINK LEC-iMX95
SMARC module based on the NXP i.MX95 processor.

The series includes:
- ADLINK LEC-iMX95 board support
- LEC-iMX95 device tree and U-Boot-specific device-tree support
- LEC-iMX95 defconfig
- Board build and boot documentation

The board support includes SPL initialization, board-specific DDR
size detection, MMC environment handling and the required i.MX95
boot image packaging support.

Validation performed:
- make O=build-lec-imx95 lec-imx95_defconfig
- make O=build-lec-imx95 -j$(nproc)
- successful SPL and U-Boot build
- successful LEC-iMX95 DTB compilation
- successful Binman generation of flash.bin
- successful targeted dt-validate of lec-imx95.dtb
- git diff --check
- checkpatch.pl (0 errors; advisory warnings reviewed)

Signed-off-by: Dinesh kumar v <dinesh.v@adlinktech.com>
---
Dinesh kumar v (4):
      arm: imx9: Add ADLINK LEC-iMX95 board support
      arm: dts: imx95: Add ADLINK LEC-iMX95 device tree
      configs: Add ADLINK LEC-iMX95 defconfig
      doc: board: Add ADLINK LEC-iMX95 documentation

 arch/arm/dts/lec-imx95-u-boot.dtsi   |  73 +++++
 arch/arm/dts/lec-imx95.dts           | 216 +++++++++++++++
 arch/arm/dts/lec-imx95.dtsi          | 524 +++++++++++++++++++++++++++++++++++
 arch/arm/mach-imx/imx9/Kconfig       |  10 +-
 board/adlink/common/Makefile         |  26 ++
 board/adlink/common/mmc.c            |  49 ++++
 board/adlink/lec_imx95/Kconfig       |  20 ++
 board/adlink/lec_imx95/MAINTAINERS   |   7 +
 board/adlink/lec_imx95/Makefile      |  11 +
 board/adlink/lec_imx95/lec_imx95.c   |  96 +++++++
 board/adlink/lec_imx95/lec_imx95.env |  75 +++++
 board/adlink/lec_imx95/spl.c         |  79 ++++++
 configs/lec-imx95_defconfig          | 153 ++++++++++
 doc/board/adlink/lec-imx95.rst       | 183 ++++++++++++
 include/configs/lec_imx95.h          |  27 ++
 15 files changed, 1548 insertions(+), 1 deletion(-)
---
base-commit: 2b8902913c19eb581fb0d567201c09b8fa46ac74
change-id: 20260928-lec-imx95-v1-e2766e27906c

Best regards,
-- 
Dinesh kumar v <dinesh.v@adlinktech.com>

