From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH 0/5] power: supply: Add several features support in
 qcom-battmgr driver
Date: Fri, 23 May 2025 09:39:17 +0800
Message-Id: <20250523-qcom_battmgr_update-v1-0-2bb6d4e0a56e@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMXRL2gC/x3MTQqAIBBA4avErBPMmBZdJSJMJ5uF/ahFIN09a
 fkt3ssQKTBF6KsMgW6OvG8FTV2BWfXmSLAtBiUVSlRSnGb306xT8i5M12F1ItFi11iDqjMSoZR
 HoIWf/zqM7/sBQy+3umUAAAA=
X-Change-ID: 20250520-qcom_battmgr_update-3561dc526c05
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747964381; l=1544;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=BuAnjRUfiZkIyG1T0GsVaYITt5f2u03IOqolF0n/F0o=;
 b=c0WUixK9b9fxeYtk5G88417BMhrAC/WNVf04Y+Xs7UgkXbCBJZefFaiBnKKxhqb2ADCpBfIkQ
 b8fjIrU7KaFD3ZGGC2oK+RB+4pY62m630Uw+prokvzuyEhtOSnBzv3h
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add following features in qcom-battmgr drivers as the battery management
firmware has provided such capabilities:
 - Add resistance power supply property in core driver and qcom-battmgr
   driver to get battery resistance
 - Add state_of_health power supply property in core driver and
   qcom-battmgr driver to get battery health percentage
 - Add charge control start/end threshold control by using
   charge_control_start_threshold and charge_control_end_threshold power
   supply properties

The changes have been tested on QRD8650 device based on qcom/linux.git
for-next commit f8d04825b12f42ec8198dee1ab4654792f9ac231.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Fenglin Wu (5):
      power: supply: core: add resistance power supply property
      power: supply: core: Add state_of_health power supply property
      power: supply: qcom_battmgr: Add resistance power supply property
      power: supply: qcom-battmgr: Add state_of_health power supply property
      power: supply: qcom-battmgr: Add charge control support

 Documentation/ABI/testing/sysfs-class-power |  20 +++
 drivers/power/supply/power_supply_sysfs.c   |   2 +
 drivers/power/supply/qcom_battmgr.c         | 213 +++++++++++++++++++++++++++-
 include/linux/power_supply.h                |   2 +
 4 files changed, 236 insertions(+), 1 deletion(-)
---
base-commit: b1d8766052eb0534b27edda8af1865d53621bd6a
change-id: 20250520-qcom_battmgr_update-3561dc526c05

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

