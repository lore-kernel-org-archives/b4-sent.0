From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH v2 0/8] power: supply: Add several features support in
 qcom-battmgr driver
Date: Fri, 30 May 2025 15:35:05 +0800
Message-Id: <20250530-qcom_battmgr_update-v2-0-9e377193a656@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKlfOWgC/22NywqDMBBFf0Vm3UgSmyy66n8UkTymGqhGkxgs4
 r83FbrrZuBc7j2zQ8TgMMKt2iFgdtH5qQC/VGAGNfVInC0MnHJBBadkMX7stEpp7EO3zlYlJI2
 QzBrBpaECynIO+HTbaX20hQcXkw/v80lm3/Tna/76MiOUcK2lvSJVQuLdx1gvq3qV8liXA+1xH
 B9fkFb7vQAAAA==
X-Change-ID: 20250520-qcom_battmgr_update-3561dc526c05
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748590538; l=3179;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=5HxqNMeD1/f7YQnN7xhf+npL6xt1LWEI9PtEr8GuJRs=;
 b=hSy5b3n5jlNd/kBYUZ6n/phnURJVIB+JxwC6vo/qUrAwrhgsODUlTHSxJc7W9F0InrD/xTjvh
 CXxmRPTdk/yAsgwmuk4UXFkgVQriEH+2NbQ/9eyZl4mZS2kWgssyRIc
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

The changes have been tested on QRD8650 and X1E80100-CRD devices based on
qcom/linux.git for-next commit f8d04825b12f42ec8198dee1ab4654792f9ac231.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Changes in v2:
- Corrected "qcom-battmgr" to "qcom_battmgr" in the commit subject of
  patch 4/5.
- Added charge control support for X1E80100 platform in patch 5.
- X1E80100 is no longer a fallback of SM8550 in pmic-glink battmgr support,
  hence added patch 6 in the pmic-glink binding to move X1E80100 out of the
  fallbacks.
- Added patch 7 in glink-ucsi driver to include UCSI quirk for X1E80100
  platform
- Added patch 8 to remove "qcom,sm8550-pmic-glink" compatible string in
  x1* board files.
- Rebased the changes on qcom/linux.git for-next commit 44ef9ab4baaf496d227ab98d368016700f0b9300.
- Link to v1: https://lore.kernel.org/r/20250523-qcom_battmgr_update-v1-0-2bb6d4e0a56e@oss.qualcomm.com

---
Fenglin Wu (8):
      power: supply: core: Add resistance power supply property
      power: supply: core: Add state_of_health power supply property
      power: supply: qcom_battmgr: Add resistance power supply property
      power: supply: qcom_battmgr: Add state_of_health property
      power: supply: qcom_battmgr: Add charge control support
      dt-bindings: soc: qcom: pmic-glink: Move X1E80100 out of fallbacks
      usb: typec: ucsi_glink: Add UCSI quirk for X1E80100 platform
      arm64: dts: qcom: x1*: Remove qcom,sm8550-pmic-glink fallback

 Documentation/ABI/testing/sysfs-class-power        |  20 ++
 .../bindings/soc/qcom/qcom,pmic-glink.yaml         |   4 +-
 arch/arm64/boot/dts/qcom/x1-crd.dtsi               |   1 -
 arch/arm64/boot/dts/qcom/x1e001de-devkit.dts       |   1 -
 .../dts/qcom/x1e78100-lenovo-thinkpad-t14s.dtsi    |   1 -
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   |   1 -
 .../boot/dts/qcom/x1e80100-dell-xps13-9345.dts     |   1 -
 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     |   1 -
 .../boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts  |   1 -
 .../boot/dts/qcom/x1e80100-microsoft-romulus.dtsi  |   1 -
 arch/arm64/boot/dts/qcom/x1e80100-qcp.dts          |   1 -
 drivers/power/supply/power_supply_sysfs.c          |   2 +
 drivers/power/supply/qcom_battmgr.c                | 275 ++++++++++++++++++++-
 drivers/usb/typec/ucsi/ucsi_glink.c                |   1 +
 include/linux/power_supply.h                       |   2 +
 15 files changed, 295 insertions(+), 18 deletions(-)
---
base-commit: abbf1025002e4966bfcbf8a069234e485d49edf1
change-id: 20250520-qcom_battmgr_update-3561dc526c05

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

