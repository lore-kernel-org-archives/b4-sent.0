From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH v4 0/8] power: supply: Add several features support in
 qcom-battmgr driver
Date: Mon, 15 Sep 2025 16:49:52 +0800
Message-Id: <20250915-qcom_battmgr_update-v4-0-6f6464a41afe@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADHTx2gC/3XOSwqDMBAG4KtI1o3kbe2q9yhFoo4aqK9EQ4t49
 0ahtAu7GfiHmW9mQQ6sAYcu0YIseONM34UgThEqGt3VgE0ZMmKESSIZwWPRt1mup6mtbTYPpZ4
 Ac6loWUimCiJR2BwsVOa5q7d7yI1xU29f+xFPt+7H44eep5hglueqFEC0VHDtnYvHWT/CcBuHg
 jbWsx+KH7/mWaBS4ElCU66VVH8o/qXOTB1TPFCJAC0ogYqKI2pd1zcuVmtpUwEAAA==
X-Change-ID: 20250520-qcom_battmgr_update-3561dc526c05
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 =?utf-8?q?Gy=C3=B6rgy_Kurucz?= <me@kuruczgy.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757926212; l=4444;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=GzMEP1IS+VspB7xroNMqPQCpbCwhUyGPjJdFRa+ID4s=;
 b=ozQUdN0R/AiNG9imL+B95s8aXd8+EEQ5V9kkWyJWVAaU+0qY+AMoVAs+cBMLEsyzSXq9QQIO3
 w8cYbWWUFk4Ccx0I0KEkesFly8rVgSyPw5iDSYNCexgbj0PWMyT+Bjh
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
qcom/linux.git for-next commit a679f3f6931cdb0c2ef5dc0c26f895ae3f6c1ddc.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Changes in v4:
- Address review comments from Maud and Konrad in [PATCH v3 8/8]:
  - Fix the address typo in nvmem cell node name "charge-limit-delta@75"
  - Add a blank line after the nvmem cell DT assignments
- Retrieve code-review trailers
- Link to v3: https://lore.kernel.org/r/20250826-qcom_battmgr_update-v3-0-74ea410ef146@oss.qualcomm.com

Changes in v3:
- Change power supply property "RESISTANCE" to "INTERNAL_RESISTANCE" and
  update the ABI document accordingly.
- Update the ABI document for "STATE_OF_HEALTH" property to explain it
  better.
- Drop following patches, as they were made due to my misunderstanding of
  the compats fallback behavior. Thank you to Krzysztof for the correction
  with patience.
    [PATCH v2 6/8] dt-bindings: soc: qcom: pmic-glink: Move X1E80100 out of fallbacks
    [PATCH v2 7/8] usb: typec: ucsi_glink: Add UCSI quirk for X1E80100 platform
    [PATCH v2 8/8] arm64: dts: qcom: x1*: Remove qcom,sm8550-pmic-glink fallback
- Addressed several comments in [PATCH v2 5/8]:
   - Separated the compat string addition change
   - Fixed the coding style issues in several places to address this
     checkpatch error:
       "CHECK: Alignment should match open parenthesis"
   - Add logic to read charge control thresholds from SDAM registers in driver
     probe. It addresses the issue on X1E80100, where there is no interface
     to retrieve the thresholds from the battery management firmware after
     boot-up.
- Add a DT binding change for charge_limit_xx "nvmem" DT properties.
- Add a DT change to specifiy charge_limit_xx "nvmem" properties for X1E80100
  devices.
- Link to v2: https://lore.kernel.org/r/20250530-qcom_battmgr_update-v2-0-9e377193a656@oss.qualcomm.com

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
      power: supply: qcom_battmgr: update compats for SM8550 and X1E80100
      dt-bindings: soc: qcom,pmic-glink: Add charge limit nvmem properties
      power: supply: qcom_battmgr: Add charge control support
      arm64: dts: qcom: x1e80100-crd: Add charge limit nvmem

 Documentation/ABI/testing/sysfs-class-power        |  31 ++
 .../bindings/soc/qcom/qcom,pmic-glink.yaml         |  14 +
 arch/arm64/boot/dts/qcom/x1-crd.dtsi               |   3 +
 arch/arm64/boot/dts/qcom/x1e80100-pmics.dtsi       |  20 ++
 drivers/power/supply/power_supply_sysfs.c          |   2 +
 drivers/power/supply/qcom_battmgr.c                | 316 ++++++++++++++++++++-
 include/linux/power_supply.h                       |   2 +
 7 files changed, 379 insertions(+), 9 deletions(-)
---
base-commit: abbf1025002e4966bfcbf8a069234e485d49edf1
change-id: 20250520-qcom_battmgr_update-3561dc526c05

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

