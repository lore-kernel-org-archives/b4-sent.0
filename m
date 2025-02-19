From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH 0/5] Driver for Apple ISP and cameras.
Date: Wed, 19 Feb 2025 10:26:56 +0100
Message-Id: <20250219-isp-v1-0-6d3e89b67c31@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOCjtWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0ML3cziAl3TlETDlKRk8xQTcyMloMqCotS0zAqwKdGxtbUAwv7hj1U
 AAAA=
X-Change-ID: 20250218-isp-5da1dbc7d472
To: Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-media@vger.kernel.org, imx@lists.linux.dev, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Asahi Lina <lina@asahilina.net>, 
 Eileen Yoon <eyn@gmx.com>, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739957223; l=3672;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=pwGGm2Hm5mZhaIRDSeBjgUFdbUBMVkomGoaRRRL0SIc=;
 b=nvrbV1AEtw0ERqvWR3g+Y/OsdqGht+NJ9fo0RU0M70XuBvmPXcB3WJWvOmNNO0rWQafgXj7Ii
 Hpee0XOWX64Auuix7clIRjMzRrVaziNinC0Oe91ZTvLclhYM+ozLWho
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This series adds support for the camera and ISP system present
on Apple devices using M-series chips. This is a "simple" camera
and does not need any special userspace handling, everything
is handled by the firmware running on an ASC coprocessor.

Patches 1 and 2 add support for special handling neccesary for the
ISP power domains. The rest add the driver itself.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Asahi Lina (1):
      pmdomain: apple: Add force-disable/force-reset

Eileen Yoon (2):
      media: apple: Add Apple ISP driver
      arm64: dts: apple: Add ISP nodes

Sasha Finkelstein (2):
      dt-bindings: power: apple,pmgr-pwrstate: Add force-{disable,reset} properties
      media: dt-bindings: Add Apple ISP

 .../devicetree/bindings/media/apple,isp.yaml       | 151 ++++
 .../bindings/power/apple,pmgr-pwrstate.yaml        |  10 +
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/isp-common.dtsi          |  45 ++
 arch/arm64/boot/dts/apple/isp-imx248.dtsi          |  62 ++
 arch/arm64/boot/dts/apple/isp-imx364.dtsi          |  78 ++
 arch/arm64/boot/dts/apple/isp-imx558-cfg0.dtsi     | 101 +++
 arch/arm64/boot/dts/apple/isp-imx558.dtsi          | 102 +++
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          |  48 ++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi     |   6 +
 arch/arm64/boot/dts/apple/t600x-pmgr.dtsi          |  81 ++
 arch/arm64/boot/dts/apple/t8103-j293.dts           |   6 +
 arch/arm64/boot/dts/apple/t8103-j313.dts           |   6 +
 arch/arm64/boot/dts/apple/t8103-j456.dts           |   6 +
 arch/arm64/boot/dts/apple/t8103-j457.dts           |   6 +
 arch/arm64/boot/dts/apple/t8103-pmgr.dtsi          | 118 +++
 arch/arm64/boot/dts/apple/t8103.dtsi               |  50 ++
 arch/arm64/boot/dts/apple/t8112-j413.dts           |   7 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |   6 +
 arch/arm64/boot/dts/apple/t8112-pmgr.dtsi          | 118 +++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  50 ++
 drivers/media/platform/Kconfig                     |   1 +
 drivers/media/platform/Makefile                    |   1 +
 drivers/media/platform/apple/Kconfig               |   5 +
 drivers/media/platform/apple/Makefile              |   3 +
 drivers/media/platform/apple/isp/Kconfig           |  16 +
 drivers/media/platform/apple/isp/Makefile          |   3 +
 drivers/media/platform/apple/isp/isp-cam.c         | 414 ++++++++++
 drivers/media/platform/apple/isp/isp-cam.h         |  21 +
 drivers/media/platform/apple/isp/isp-cmd.c         | 635 +++++++++++++++
 drivers/media/platform/apple/isp/isp-cmd.h         | 692 ++++++++++++++++
 drivers/media/platform/apple/isp/isp-drv.c         | 586 ++++++++++++++
 drivers/media/platform/apple/isp/isp-drv.h         | 284 +++++++
 drivers/media/platform/apple/isp/isp-fw.c          | 770 ++++++++++++++++++
 drivers/media/platform/apple/isp/isp-fw.h          |  24 +
 drivers/media/platform/apple/isp/isp-iommu.c       | 251 ++++++
 drivers/media/platform/apple/isp/isp-iommu.h       |  20 +
 drivers/media/platform/apple/isp/isp-ipc.c         | 258 ++++++
 drivers/media/platform/apple/isp/isp-ipc.h         |  25 +
 drivers/media/platform/apple/isp/isp-regs.h        |  56 ++
 drivers/media/platform/apple/isp/isp-v4l2.c        | 900 +++++++++++++++++++++
 drivers/media/platform/apple/isp/isp-v4l2.h        |  16 +
 drivers/pmdomain/apple/pmgr-pwrstate.c             |  43 +-
 43 files changed, 6077 insertions(+), 6 deletions(-)
---
base-commit: 2408a807bfc3f738850ef5ad5e3fd59d66168996
change-id: 20250218-isp-5da1dbc7d472

