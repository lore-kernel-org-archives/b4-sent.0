From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v3 0/8] arm64: dts: freescale: Add support for the
 GOcontroll Moduline Display
Date: Thu, 27 Mar 2025 16:52:35 +0100
Message-Id: <20250327-initial_display-v3-0-4e89ea1676ab@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEN05WcC/3XN0QqDIBTG8VcZXs+hx2yxq73HGMNM64DT0JBF9
 O6zrgaxy/8H53cWkkxEk8jttJBoMiYMvoQ4n4gelO8Nxa40AQaSAVQUPU6o3KvDNDo1U6saAN4
 YVhtJytUYjcXPLj6epQdMU4jz/iDzbf1vZU4ZlVq3ra25kJW490EHP8Xg3EWHN9nADL9IfUSgI
 CCssooL1vDrAVnX9QsP+up8+AAAAA==
X-Change-ID: 20250224-initial_display-fa82218e06e5
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743090757; l=2483;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=I5laCEMQQhC0jxJBzqkC6My5Y526yISp6HHNhnXyuoI=;
 b=7DfLoLe9EHr2CxFXvsX6B+b2N2FuAwbJ+o+BEYbd6wpwbYIid1+B5/IKTuFBwhZVf4HHD+v0f
 2MfEWUPAeUXCwNe5Vq4ivu3U5n2JEq25qg4sHgEjtUnRwov9iX1+Z6C
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inital support for 2 variants of the Moduline Display controller.
This system is powered by the Ka-Ro Electronics tx8p-ml81 COM, which
features an imx8mp SoC.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
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
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h     |  27 +
 ...tx8p-ml81-moduline-display-106-av101hdt-a10.dts | 100 ++++
 ...tx8p-ml81-moduline-display-106-av123z7m-n17.dts | 133 +++++
 .../imx8mp-tx8p-ml81-moduline-display-106.dtsi     | 535 ++++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi | 549 +++++++++++++++++++++
 7 files changed, 1357 insertions(+)
---
base-commit: db8da9da41bced445077925f8a886c776a47440c
change-id: 20250224-initial_display-fa82218e06e5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

