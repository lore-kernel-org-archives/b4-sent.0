From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v6 0/8] arm64: dts: freescale: Add support for the
 GOcontroll Moduline Display
Date: Thu, 17 Apr 2025 12:14:01 +0200
Message-Id: <20250417-initial_display-v6-0-3c6f6d24c7af@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGnUAGgC/3XNzYrDIBSG4Vsprseix59oV72PMgzGaHsgE4uGM
 KXk3sd204Lp8v3gPOdOSsgYCjns7iSHBQumqYb+2hF/cdM5UBxqE2CgGICkOOGMbvwZsFxHd6P
 RGQBuAtNBkXp1zSHi31M8fde+YJlTvj0fLPyxfrYWThlV3vd91FwoKY7n5NM05zSOe59+yQNc4
 B3RLQIVARFddFwww7tNRLwQAV2LiIrIYGxwXHfa9ZuIfCGSQYvIithorDHCOKPlJqLeEK5aRFU
 kCladoePS2gZZ1/UfpAYd6scBAAA=
X-Change-ID: 20250224-initial_display-fa82218e06e5
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>, Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744884848; l=3701;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=OH7eZX54zgQCjVVOYI4sEIr2A+p5IQRMKEHQ5gWO4Vo=;
 b=E5KfrkxKT4ITztZE9VHXJ1UMy+TBUFwiIVRtGdhi8AJLHgzFtO3Ti6Xk8d9b702xDuV1xwg5h
 GkQi4hhLOy8DXbqlcFul8IeIjVDMQ1b8ruDaiEGXhckZivbPWmsZnbf
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inital support for 2 variants of the Moduline Display controller.
This system is powered by the Ka-Ro Electronics tx8p-ml81 COM, which
features an imx8mp SoC.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Changes in v6:
- Fix spi cs formatting in baseboard dts
- Add model to baseboard dts
- Fix commit typo in karo tx8p ml81 dtsi
- Link to v5: https://lore.kernel.org/r/20250415-initial_display-v5-0-f309f8d71499@gocontroll.com

Changes in v5:
- Merge the makefile patch into the two dtso patches
- Fix references to the root node in the dtso patches
- Enable the USB bus going to the adapter board in the mainboard dts
- Fix some formatting issues in the mainboard dts
- Fix some formatting issues in the COM dts
- Change a clock as suggested in the COM dts
- Fix the maintainers entries, remove devicetree list and imx list
- Rebase on latest linux-next
- Link to v4: https://lore.kernel.org/r/20250402-initial_display-v4-0-9f898838a864@gocontroll.com

Changes in v4:
- Add imx mailing list to ka-ro tx8p maintainer entry
- Fix several small indentation and ordering issues in devicetrees
- Change the two display adapter boards to overlays
- Add the missing patch for the Makefile to actually be able to build
  the new devicetrees
- Link to v3: https://lore.kernel.org/r/20250327-initial_display-v3-0-4e89ea1676ab@gocontroll.com

Changes in v3:
- Set regulator-boot-on and always-on on LDO5 of the pmic, after 20 ish
  seconds it auto disabled this LDO causing weird behaviour like
  ethernet droping out, wifi not working anymore. This LDO can control
  the IO voltage level of certain pins, just let it keep the u-boot
  value.
- Fix the comment style in imx8mp-pinfunc.h
- Rebase on newest next tag
- Link to v2: https://lore.kernel.org/r/20250226-initial_display-v2-0-23fafa130817@gocontroll.com

Changes in v2:
- Dropped the trivial-devices patch
- Added a patch with bindings for the gocontroll,moduline-module-slot
- Added a patch to spidev.c to enable the spidev driver for the module
  slot
- Added a missing usb-c connector in the av101hdt-a10 variant dts
- Switched to the new bindings for the module slots in the base dts
- Fixed some commit typos
- Link to v1: https://lore.kernel.org/r/20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com

---
Maud Spierings (8):
      dt-bindings: arm: fsl: Add GOcontroll Moduline Display
      arm64: dts: imx8mp: Add pinctrl config definitions
      MAINTAINERS: add maintainer for the Ka-Ro tx8p-ml81 COM module
      MAINTAINERS: add maintainer for the GOcontroll Moduline controllers
      arm64: dts: freescale: add Ka-Ro Electronics tx8p-ml81 COM
      arm64: dts: freescale: Add the GOcontroll Moduline Display baseboard
      arm64: dts: freescale: Add the BOE av101hdt-a10 variant of the Moduline Display
      arm64: dts: freescale: Add the BOE av123z7m-n17 variant of the Moduline Display

 Documentation/devicetree/bindings/arm/fsl.yaml     |   1 +
 MAINTAINERS                                        |  12 +
 arch/arm64/boot/dts/freescale/Makefile             |   8 +
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h     |  33 ++
 ...x8p-ml81-moduline-display-106-av101hdt-a10.dtso |  94 ++++
 ...x8p-ml81-moduline-display-106-av123z7m-n17.dtso | 139 ++++++
 .../imx8mp-tx8p-ml81-moduline-display-106.dts      | 526 ++++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi | 548 +++++++++++++++++++++
 8 files changed, 1361 insertions(+)
---
base-commit: fb44e19e78df2950877a9f7b4f24b58db790d293
change-id: 20250224-initial_display-fa82218e06e5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

