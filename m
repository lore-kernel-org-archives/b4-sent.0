From: Gaurav Suman <gauravsuman007@gmail.com>
Subject: [PATCH 0/8] Add SM8150 CAMSS and LG G8x ThinQ camera sensors
Date: Mon, 09 Nov 2026 22:38:18 +0000
Message-Id: <20261109-sm8150-camera-v1-0-3d2e7b407516@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFpL8moC/x3MTQqAIBBA4avIrBNUUKyrRAt/xpqFFgoRSHdPW
 n6L9zo0rIQNFtah4k2NzjIgJwbhcGVHTnEYlFBGSjHzlq3UggeXsTpuYlJCW+t9VDCaq2Ki5/+
 t2/t+AguuhF8AAAA=
X-Change-ID: 20261109-sm8150-camera-6df20588bbd2
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Gaurav Suman <gauravsuman007@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-arm-msm@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794263921; l=5453;
 i=gauravsuman007@gmail.com; s=default; h=from:subject:message-id;
 bh=V0gxOM2+wQBEiJW7jBW/SNch7ZQr8m8J9Q6jbHcbWdU=;
 b=Bj65NyVHBcsx5uucl2Sxdj4GMPIoqzce0DT+tdCySvmN00TKqBD31U4Q1VDTUGctkA/xJdWmD
 d3jWcSFHafIDDqgmgUrU38ErgAEJd/WgH3KG0NYxLgH6cOXj/x+gUSo
X-Developer-Key: i=gauravsuman007@gmail.com; a=ed25519;
 pk=lnUC0mQfc0KyA0LE73pQ4+QWYVRaCD8Sd3XWxLZO+JY=
X-Endpoint-Received: by B4 Relay for gauravsuman007@gmail.com/default with auth_id=1467
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds camera support for the Qualcomm SM8150 (Titan 175) and
the three cameras of the LG G8x ThinQ:

 - CAMSS for SM8150: four CSIPHYs, two CSIDs/VFEs plus two lite pairs,
   reusing the gen2 CSID and VFE 17x code with SM8150 clock rates, the
   CSIPHY v1.1 lane table and camnoc_axi set to 400 MHz by the driver,
 - a driver for the Samsung S5K3M3 13MP sensor (wide camera),
 - a driver for the Samsung S5KGD1 32MP quad-Bayer sensor (front
   camera, 2x2 binned mode),
 - a lens driver for the autofocus part of the ON Semiconductor
   LC898123F40 OIS/AF controller (main camera module).

The main camera, a Sony IMX363, uses the driver from the sdm670-mainline
tree (Pixel 3a), which its author plans to submit; it is not part of
this series. The board DT for the G8x will follow once the bindings are
settled.

The sensor register settings come from the phone's vendor camera module
data. Each driver supports one mode for now.

Testing: on an LG G8x ThinQ, all three sensors stream RAW10 at 30 fps
through CSID0/VFE0 RDI0 into libcamera's simple pipeline handler and
GPU software ISP (GNOME Snapshot), and the lens moves with
V4L2_CID_FOCUS_ABSOLUTE. The patches apply to next-20261105; the
drivers build with W=1 without warnings and the bindings pass
dt_binding_check. The same code runs on the phone on top of the
postmarketOS 7.0 kernel (only the client_info callback argument
differs).

Tree and test notes: https://github.com/gauravsuman007/nura-g8x

This series was written and tested with the help of an AI coding
assistant (Claude Opus 5.5, Anthropic). I have reviewed every patch and
the test results, and I am responsible for them.

Gaurav Suman (8):
  dt-bindings: media: Add qcom,sm8150-camss
  media: qcom: camss: Add SM8150 support
  dt-bindings: media: i2c: Add Samsung S5K3M3 image sensor
  media: i2c: Add Samsung S5K3M3 image sensor driver
  dt-bindings: media: i2c: Add Samsung S5KGD1 image sensor
  media: i2c: Add Samsung S5KGD1 image sensor driver
  dt-bindings: media: i2c: Add ON Semiconductor LC898123F40
  media: i2c: Add ON Semiconductor LC898123F40 lens autofocus driver

.../bindings/media/i2c/onnn,lc898123f40.yaml  |   46 +
 .../bindings/media/i2c/samsung,s5k3m3.yaml    |  104 +
 .../bindings/media/i2c/samsung,s5kgd1.yaml    |  105 +
 .../bindings/media/qcom,sm8150-camss.yaml     |  389 ++
 MAINTAINERS                                   |   25 +
 drivers/media/i2c/Kconfig                     |   30 +
 drivers/media/i2c/Makefile                    |    3 +
 drivers/media/i2c/lc898123.c                  |  138 +
 drivers/media/i2c/s5k3m3-regs.h               |   71 +
 drivers/media/i2c/s5k3m3.c                    |  451 ++
 drivers/media/i2c/s5kgd1-regs.h               | 6137 +++++++++++++++++
 drivers/media/i2c/s5kgd1.c                    |  451 ++
 .../qcom/camss/camss-csiphy-3ph-1-0.c         |   80 +
 drivers/media/platform/qcom/camss/camss-vfe.c |    2 +
 drivers/media/platform/qcom/camss/camss.c     |  250 +
 drivers/media/platform/qcom/camss/camss.h     |    1 +
 16 files changed, 8283 insertions(+)
 create mode 100644 Documentation/devicetree/bindings/media/i2c/onnn,lc898123f40.yaml
 create mode 100644 Documentation/devicetree/bindings/media/i2c/samsung,s5k3m3.yaml
 create mode 100644 Documentation/devicetree/bindings/media/i2c/samsung,s5kgd1.yaml
 create mode 100644 Documentation/devicetree/bindings/media/qcom,sm8150-camss.yaml
 create mode 100644 drivers/media/i2c/lc898123.c
 create mode 100644 drivers/media/i2c/s5k3m3-regs.h
 create mode 100644 drivers/media/i2c/s5k3m3.c
 create mode 100644 drivers/media/i2c/s5kgd1-regs.h
 create mode 100644 drivers/media/i2c/s5kgd1.c

---
Gaurav Suman (8):
      dt-bindings: media: Add qcom,sm8150-camss
      media: qcom: camss: Add SM8150 support
      dt-bindings: media: i2c: Add Samsung S5K3M3 image sensor
      media: i2c: Add Samsung S5K3M3 image sensor driver
      dt-bindings: media: i2c: Add Samsung S5KGD1 image sensor
      media: i2c: Add Samsung S5KGD1 image sensor driver
      dt-bindings: media: i2c: Add ON Semiconductor LC898123F40
      media: i2c: Add ON Semiconductor LC898123F40 lens autofocus driver

 .../bindings/media/i2c/onnn,lc898123f40.yaml       |   46 +
 .../bindings/media/i2c/samsung,s5k3m3.yaml         |  104 +
 .../bindings/media/i2c/samsung,s5kgd1.yaml         |  105 +
 .../bindings/media/qcom,sm8150-camss.yaml          |  389 ++
 MAINTAINERS                                        |   23 +
 drivers/media/i2c/Kconfig                          |   30 +
 drivers/media/i2c/Makefile                         |    3 +
 drivers/media/i2c/lc898123.c                       |  138 +
 drivers/media/i2c/s5k3m3-regs.h                    |   71 +
 drivers/media/i2c/s5k3m3.c                         |  451 ++
 drivers/media/i2c/s5kgd1-regs.h                    | 6137 ++++++++++++++++++++
 drivers/media/i2c/s5kgd1.c                         |  451 ++
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     |   80 +
 drivers/media/platform/qcom/camss/camss-vfe.c      |    2 +
 drivers/media/platform/qcom/camss/camss.c          |  250 +
 drivers/media/platform/qcom/camss/camss.h          |    1 +
 16 files changed, 8281 insertions(+)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261109-sm8150-camera-6df20588bbd2

Best regards,
-- 
Gaurav Suman <gauravsuman007@gmail.com>

