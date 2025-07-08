From: Frank Li <Frank.Li@nxp.com>
Subject: [PATCH v3 0/4] media: imx8qxp: add parallel camera support
Date: Tue, 08 Jul 2025 13:48:41 -0400
Message-Id: <20250708-imx8qxp_pcam-v3-0-c8533e405df1@nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPpZbWgC/13MSw7CIBSF4a00jMUA11bqyH0YYyrc2jtoi2AIp
 unepY2Jj+E5yf9NLKAnDOxQTMxjpEDjkAdsCma6ZrghJ5s3U0KVolIVpz7pe3IXZ5qeW11KBRp
 2YIDlxHlsKa3c6Zx3R+Ex+ueqR7m8bwjELxQlFxyNsaBtXSshj0NyWzP2bGGi+qR7AX+pyqnU+
 oq6bEXVfqXzPL8A8gzFXuEAAAA=
X-Change-ID: 20250626-imx8qxp_pcam-d851238343c3
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Rui Miguel Silva <rmfrfs@gmail.com>, 
 Martin Kepplinger <martink@posteo.de>, Purism Kernel Team <kernel@puri.sm>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-media@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Frank Li <Frank.Li@nxp.com>, 
 Alice Yuan <alice.yuan@nxp.com>, Robert Chiras <robert.chiras@nxp.com>, 
 Zhipeng Wang <zhipeng.wang_1@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751996966; l=2236;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=vyzr1Cp3VW/MJrLr8Vd9Cd8+qdk5yXeJaAIf72BHAvA=;
 b=pLkoCOPxcG5H2BqKndFzFcZrU81lbL29lhmoCGOa3QjiD2Tf8/6ldvTR9I4iEwUT7ta5zz1ZQ
 ecsvl/wP0NWAkHAFqjn2k/TZRc4T3nFIINrcvgp3Okk/Elz+pyPwJk0
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add parallel camera support for i.MX8 chips.

The below patch to add new format support to test ov5640 sensor
   media: nxp: isi: add support for UYVY8_2X8 and YUYV8_2X8 bus codes

The bindings and driver for parallel CSI
   dt-bindings: media: add i.MX parallel csi support
   media: nxp: add V4L2 subdev driver for parallel CSI

DTS part need depend on previous MIPI CSI patches.
  https://lore.kernel.org/imx/20250522-8qxp_camera-v5-13-d4be869fdb7e@nxp.com/

  arm64: dts: imx8: add parellel csi nodes
  arm64: dts: imx8qxp-mek: add parallel ov5640 camera support

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
Changes in v3:
- replace CSI with CPI.
- detail change see each patch's change logs
- Link to v2: https://lore.kernel.org/r/20250703-imx8qxp_pcam-v2-0-188be85f06f1@nxp.com

Changes in v2:
- remove patch media: nxp: isi: add support for UYVY8_2X8 and YUYV8_2X8 bus codes
  because pcif controller convert 2x8 to 1x16 to match isi's input
- rename comaptible string to fsl,imx8qxp-pcif
- See each patches's change log for detail
- Link to v1: https://lore.kernel.org/r/20250630-imx8qxp_pcam-v1-0-eccd38d99201@nxp.com

---
Alice Yuan (2):
      dt-bindings: media: add i.MX parallel CPI support
      media: nxp: add V4L2 subdev driver for camera parallel interface (CPI)

Frank Li (2):
      arm64: dts: imx8: add camera parallel interface (CPI) node
      arm64: dts: imx8qxp-mek: add parallel ov5640 camera support

 .../devicetree/bindings/media/fsl,imx93-pcif.yaml  | 126 +++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/freescale/Makefile             |   3 +
 arch/arm64/boot/dts/freescale/imx8-ss-img.dtsi     |  13 +
 .../boot/dts/freescale/imx8qxp-mek-ov5640-cpi.dtso |  82 ++
 arch/arm64/boot/dts/freescale/imx8qxp-ss-img.dtsi  |  27 +
 drivers/media/platform/nxp/Kconfig                 |  11 +
 drivers/media/platform/nxp/Makefile                |   1 +
 drivers/media/platform/nxp/imx-parallel-cpi.c      | 920 +++++++++++++++++++++
 9 files changed, 1185 insertions(+)
---
base-commit: 93355cfe8aec9e47fc93fbc940f1bbeedd62e249
change-id: 20250626-imx8qxp_pcam-d851238343c3

Best regards,
--
Frank Li <Frank.Li@nxp.com>

