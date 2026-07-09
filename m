From: HaoNing Cheng <Haoning.CHENG@cn.bosch.com>
Subject: [PATCH 0/2] thermal: imx: Add calibration offset support
Date: Thu, 09 Jul 2026 13:43:26 +0800
Message-Id: <20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-v1-0-00f88f42930b@cn.bosch.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP40T2oC/yXNQQ7CIBCF4as0s3YSIIRSr2JcQDtajLSEAVPT9
 O6ibl7ybd6/A1MOxHDudsj0ChzWpUGeOhhnt9wJw9QMSigjejGg18jv6BanJEqp2oa4YZkpR/d
 ErimtuWBNXDK5iAalRSesHqyeyPcG2nPKdAvbr3q5/s3VP2gs3xQcxweapxislwAAAA==
X-Change-ID: 20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-a084984deb76
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Haoning CHENG <Haoning.CHENG@cn.bosch.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783575916; l=1237;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=WbMChnrVJ5hLjteSDIcwpCRJ7d6FUBqAjyKBvueOBbk=;
 b=WqH42b8JtaKetUkHD06W8GNAZAw0KozZWsslG7Ipqvnb+EYgHYP8NqvJfBOBEGbSM6bSooo1o
 nWVtP19QWlOAX+w3nngyrP1CIkHZCbSldQtk5eiLEPKYL8xtICKNCmS
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some i.MX boards need a small per-design correction to align the
reported CPU temperature with board-level measurements. This series
adds an optional DT property to specify such a calibration offset
and implements the corresponding support in the imx_thermal driver.

Patch 1 documents the new fsl,temp-calibration-offset-millicelsius
property in the i.MX thermal DT binding.

Patch 2 reads this property in the imx_thermal driver and applies
the offset to the i.MX6/6SX/7D calibration formulas. When the
property is absent, the default offset remains 0, preserving the
current behaviour.

Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
---
HaoNing Cheng (2):
      dt-bindings: thermal: imx: Document calibration offset property
      thermal/drivers/imx: Add calibration offset support

 Documentation/devicetree/bindings/thermal/imx-thermal.yaml |  8 ++++++++
 drivers/thermal/imx_thermal.c                              | 11 ++++++++---
 2 files changed, 16 insertions(+), 3 deletions(-)
---
base-commit: c50a940dcde35c647e097e89a9150003abd48329
change-id: 20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-a084984deb76

Best regards,
--  
Haoning CHENG <Haoning.CHENG@cn.bosch.com>

