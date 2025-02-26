From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v2 00/12] arm64: dts: freescale: Add support for the
 GOcontroll Moduline Display
Date: Wed, 26 Feb 2025 15:19:11 +0100
Message-Id: <20250226-initial_display-v2-0-23fafa130817@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN8iv2cC/3WNQQqDMBBFryKzbkoyGpGueg+REuOoA2kiiUhFv
 HtT912+B//9AxJFpgSP4oBIGycOPgPeCrCz8RMJHjIDStQSsRLseWXjXgOnxZldjKZBVA3JmjT
 k1RJp5M9VbLvMM6c1xP062NTP/m9tSkihre37sValrsrnFGzwawzO3W14Q3ee5xejftpzswAAA
 A==
X-Change-ID: 20250224-initial_display-fa82218e06e5
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Liu Ying <victor.liu@nxp.com>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-spi@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740579556; l=2470;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=qPNp8kJ1SPfm9hzzYuFUJ6PYED9G/nfRjZrkm1H8psw=;
 b=RO2wdKrxZIYN3bZWZRvWLLnJ4q4OJ3zzHkzPM4aFfF+XjDIXbjVCFjRpeOidaQRPXZt2qJz7l
 zFN4KACCPHFDLlu/B1Tc95xI78GkFMvm5PPtjNbTX4mec1Lj8g+V8Sc
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inital support for 2 variants of the Moduline Display controller.
This system is powered by the Ka-Ro Electronics tx8p-ml81 COM, which
features an imx8mp SoC.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
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
Maud Spierings (12):
      dt-bindings: arm: fsl: Add GOcontroll Moduline Display
      dt-bindings: vendor-prefixes: add GOcontroll
      dt-bindings: connector: Add the GOcontroll Moduline module slot bindings
      arm64: dts: imx8mp: Add pinctrl config definitions
      MAINTAINERS: add maintainer for the Ka-Ro tx8p-ml81 COM module
      MAINTAINERS: add maintainer for the GOcontroll Moduline module slot
      MAINTAINERS: add maintainer for the GOcontroll Moduline controllers
      arm64: dts: freescale: add Ka-Ro Electronics tx8p-ml81 COM
      arm64: dts: freescale: Add the GOcontroll Moduline Display baseboard
      arm64: dts: freescale: Add the BOE av101hdt-a10 variant of the Moduline Display
      arm64: dts: freescale: Add the BOE av123z7m-n17 variant of the Moduline Display
      spi: spidev: Add an entry for the gocontroll moduline module slot

 Documentation/devicetree/bindings/arm/fsl.yaml     |   1 +
 .../connector/gocontroll,moduline-module-slot.yaml |  88 ++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  17 +
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h     |  27 +
 ...tx8p-ml81-moduline-display-106-av101hdt-a10.dts | 100 ++++
 ...tx8p-ml81-moduline-display-106-av123z7m-n17.dts | 133 +++++
 .../imx8mp-tx8p-ml81-moduline-display-106.dtsi     | 535 ++++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi | 547 +++++++++++++++++++++
 drivers/spi/spidev.c                               |   2 +
 10 files changed, 1452 insertions(+)
---
base-commit: 2bc63dbeabecce860eb8b261bf67b97552fe7747
change-id: 20250224-initial_display-fa82218e06e5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

