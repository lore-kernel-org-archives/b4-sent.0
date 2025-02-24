From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 00/14] arm64: dts: freescale: Add support for the
 GOcontroll Moduline Display
Date: Mon, 24 Feb 2025 14:50:50 +0100
Message-Id: <20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADp5vGcC/x3M0QpAMBSH8VdZ59pqTkheRdKyg39p1iaRvLvl8
 nfxfQ8liZBEnXooyomE3WeUhaJptX4RDZdNbLg2zJWGxwG7jQ4pbPbWs22Zy1ZMIzXlKkSZcf3
 HfnjfD16CHDdhAAAA
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
 Fabio Estevam <festevam@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740405062; l=2195;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=VEEv6nk8vDex2BIMDGcyoeXhYWRBAy36ZB74OSyadLQ=;
 b=fKWlALGDjjqxq4Z193T7Ci/ahYXLxryiGGIkZwxtx0yJxz7Sffnh3789/tCcMZcJS7qRSZ0SC
 OXfDAtd+vzFBxMyTIjw8WpoWUMc911QpWUXsBSVw5lsld0AipyD649U
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inital support for 2 variants of the Moduline Display controller.
This system is powered by the Ka-Ro Electronics tx8p-ml81 COM, which
features an imx8mp SoC.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (14):
      dt-bindings: display: simple: add BOE AV101HDT-A10 panel
      dt-bindings: display: simple: Add BOE AV123Z7M-N17 panel
      dt-bindings: arm: fsl: Add GOcontroll Moduline Display
      dt-bindings: vendor-prefixes: add GOcontroll
      dt-bindings: trivial-devices: add GOcontroll Moduline IO modules
      arm64: dts: imx8mp: Add pinctrl config definitions
      drm/panel: simple: add BOE AV101HDT-A10 panel
      drm/panel: simple: Add BOE AV123Z7M-N17 panel
      MAINTAINERS: add maintainer for the Ka-Ro tx8p-ml81 COM module
      MAINTAINERS: add maintainer for the GOcontroll Moduline controllers
      arm64: dts: freescale: add Ka-Ro Electronics tx8p-ml81 COM
      arm64: dts: freescale: Add the GOcontroll Moduline Display baseboard
      arm64: dts: freescale: Add the BOE av101hdt-a10 variant of the Moduline Display
      arm64: dts: freescale: Add the BOE av123z7m-n17 variant of the Moduline Display

 Documentation/devicetree/bindings/arm/fsl.yaml     |   1 +
 .../panel/panel-simple-lvds-dual-ports.yaml        |   2 +
 .../bindings/display/panel/panel-simple.yaml       |   2 +
 .../devicetree/bindings/trivial-devices.yaml       |   2 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  12 +
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h     |  27 +
 ...tx8p-ml81-moduline-display-106-av101hdt-a10.dts |  60 +++
 ...tx8p-ml81-moduline-display-106-av123z7m-n17.dts | 133 +++++
 .../imx8mp-tx8p-ml81-moduline-display-106.dtsi     | 530 ++++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi | 547 +++++++++++++++++++++
 drivers/gpu/drm/panel/panel-simple.c               |  64 +++
 12 files changed, 1382 insertions(+)
---
base-commit: d4b0fd87ff0d4338b259dc79b2b3c6f7e70e8afa
change-id: 20250224-initial_display-fa82218e06e5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

