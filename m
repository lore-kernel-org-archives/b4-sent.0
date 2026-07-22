From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Subject: [PATCH v11 0/3] thermal: imx: Add calibration offset support
Date: Wed, 22 Jul 2026 10:11:40 +0800
Message-Id: <20260722-b4-symana21-11221-imx-thermal-support-upstream-6-18-v11-0-90e4e46c0a13@cn.bosch.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANwmYGoC/63SS27DIBAG4KtUXpdowDy76j2qLgAPtav6IXCsR
 FHuXpxsrIqV6w3SoBHfAP+tShg7TNXby62KuHSpG4dcUPr6UvnWDl9IuiZvVAyYBAWGOE7Stbe
 DZZRQyvLa9Rcytxh7+0PSeZrGOJPzlOaItieSUE0saG40b9ApWeWTp4ihuzzYj89nnc7uG/28U
 mtH26V5jNfHXAtd+/43wUIJEICgdeDM1ODe/XByY/LtyY99tQ6xsAMY9mSCYtwIZLzA1BuGwj6
 mzkzjTPDMcOWFKDD8AIZnhgYMRjXUKwEFRmyZeh8jMiMNB+FrkF6W/kYewMjMaG1rpYNFb0uPp
 g5g1BoB42TOujQOaYHRW4bvY/QaAcEbLQ0glVhgzJZR+xiTGSUCt0EbxUMp0BQ2DtsZtRxRIEH
 7uvGNsUL9vc/9fv8FYTwDiq0EAAA=
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
 linux-kernel@vger.kernel.org, Haoning CHENG <Haoning.CHENG@cn.bosch.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784687940; l=7161;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=z/jNilZOYY/Zc7DlOq8LIcsaQEwxg/bufQsUlY4g1UI=;
 b=Pid1n7To2ODZsNEs9SmBRJTIk8mTRSOEv9G7xm9ZTANGrVMzyjN2rw71g11NSP7m8HL2T+d+z
 fOBVtK9wqhxD2KnpynFnuR2lAbtyLo3VXYNhDBFiWXu1zRKaVvltrCt
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TEMPMON sensor reading may deviate from the theoretical SoC
junction temperature. This series adds an optional DT property to
specify a calibration offset and implements the corresponding
support in the imx_thermal driver.

Patch 1 documents the new fsl,temp-calibration-offset-millicelsius
property in the i.MX thermal DT binding. The offset is determined
through thermal characterization by comparing the sensor output
against the calculated junction temperature, and is limited to
±20 °C.

Patch 2 fixes the i.MX7D alarm temperature conversion to use
ceiling division (DIV_ROUND_UP() for non-negative, plain /
for negative) and clamp() to stay within the 9-bit register range.

Patch 3 reads this property in the imx_thermal driver and applies
the offset symmetrically: it is added when reporting temperature to
the thermal framework and subtracted when programming hardware alarm
thresholds (to keep trip point semantics consistent). Out-of-range
values are rejected with -EINVAL at probe time. When the property
is absent, the default offset is 0.

Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
---
Changes in v11:
- Cover letter and patch 3: removed the claim that the TEMPMON sensor
  deviation exists "at the die level without board influence". The
  commit messages now describe what the offset does without speculating
  on the origin of the residual error.
- No code or binding changes.
- Link to v10: https://patch.msgid.link/20260720-b4-symana21-11221-imx-thermal-support-upstream-6-18-v10-0-f8c3dcd9a57e@cn.bosch.com

Changes in v10:
- Rephrase the series to describe the offset as sensor calibration
  toward the theoretical junction temperature, reverting the v9
  terminology that characterized it as a board-specific die-to-package-
  surface conversion. Hardware characterization confirmed the deviation
  exists at the die level, independent of board influence.
- dt-bindings: update the property description to state the offset
  corrects the TEMPMON sensor reading toward the theoretical junction
  temperature
- driver commit message: replace package-surface estimate wording with
  calibrated correction toward junction temperature
- Link to v9: https://patch.msgid.link/20260717-b4-symana21-11221-imx-thermal-support-upstream-6-18-v9-0-75f4af8974f4@cn.bosch.com

Changes in v9:
- Rephrase the series to clarify that the offset converts the internal
  TEMPMON reading to a package-surface temperature estimate, rather than
  calibrating the sensor for better die temperature accuracy (Frieder)
- dt-bindings: update the property description to explicitly state it is
  a board-specific conversion offset, not a sensor calibration
- driver commit message: distinguish die temperature from package-surface
  temperature in the symmetric offset mechanism explanation
- Pick up Reviewed-by tags from Frank Li (patches 2,3) and Lukasz Luba
  (patches 1,2,3)
- Link to v8: https://patch.msgid.link/20260714-b4-symana21-11221-imx-thermal-support-upstream-6-18-v8-0-d54d8690e16e@cn.bosch.com

Changes in v8:
- binding: s/behaviour/behavior/ (Lukasz)
- New prep patch: use ceiling division (DIV_ROUND_UP() for non-negative, plain /
  for negative) and clamp() for i.MX7D, extracted into a separate patch (Frank)
- driver commit message: add offset mechanism explanation with a +3000 m°C calculation example (Lukasz)
- probe: reject out-of-range offset with -EINVAL instead of silently clamping (Lukasz)
- prep patch: handle negative alarm_temp with plain division (C rounds toward zero)
- Link to v7: https://patch.msgid.link/20260713-b4-symana21-11221-imx-thermal-support-upstream-6-18-v7-0-09b6b7669be1@cn.bosch.com

Changes in v7:
- Align the author name with the Signed-off-by trailer.
- Link to v6: https://patch.msgid.link/20260713-b4-symana21-11221-imx-thermal-support-upstream-6-18-v6-0-88a378faeca5@cn.bosch.com

Changes in v6:
- Align the author name with the Signed-off-by trailer.
- Link to v5: https://patch.msgid.link/20260713-b4-symana21-11221-imx-thermal-support-upstream-6-18-v5-0-69405c306c6b@cn.bosch.com

Changes in v5:
- Move calibration offset application out of c2 initialization, instead
  apply it in imx_get_temp(), imx_set_alarm_temp() and imx_set_panic_temp()
  for consistent style across i.MX6 and i.MX7D
- Subtract calibration offset from alarm_temp before the if-else block in
  imx_set_alarm_temp(), simplifying both SoC branches (Frank's suggestion)
- Link to v4: https://patch.msgid.link/20260710-b4-symana21-11221-imx-thermal-support-upstream-6-18-v4-0-1fef97d1c750@cn.bosch.com

Changes in v4:
- dt-bindings: drop maxItems to allow minimum/maximum constraints for
  temp-calibration-offset-millicelsius
- Link to v3: https://patch.msgid.link/20260710-b4-symana21-11221-imx-thermal-support-upstream-6-18-v3-0-db9fc2947c55@cn.bosch.com

Changes in v3:
- dt-bindings: add minimum/maximum (-28580/+28580) for
  temp-calibration-offset-millicelsius, as suggested by Conor Dooley
- Link to v2: https://patch.msgid.link/20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-v2-0-00ff72495e24@cn.bosch.com

Changes in v2:
- dt-bindings: Removed explicit `$ref: /schemas/types.yaml#/definitions/int32`
  for fsl,temp-calibration-offset-millicelsius; the `-millicelsius` suffix
  already resolves to int32-array via property-units.yaml (Rob).
- dt-bindings: Fixed example indentation.
- driver: Replaced C integer division (/) with DIV_ROUND_CLOSEST() in
  imx_set_alarm_temp() to prevent off-by-one alarm threshold mismatch that
  could cause IRQ storms on i.MX7D.
- driver: Added clamp() bounds check for alarm_value [0, 0x1ff] to avoid
  corrupting adjacent register fields (PANIC_ALARM).
- Link to v1: https://patch.msgid.link/20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-v1-0-00f88f42930b@cn.bosch.com

To: "Rafael J. Wysocki" <rafael@kernel.org>
To: Daniel Lezcano <daniel.lezcano@linaro.org>
To: Zhang Rui <rui.zhang@intel.com>
To: Lukasz Luba <lukasz.luba@arm.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Shawn Guo <shawnguo@kernel.org>
To: Sascha Hauer <s.hauer@pengutronix.de>
To: Pengutronix Kernel Team <kernel@pengutronix.de>
To: Fabio Estevam <festevam@gmail.com>
Cc: linux-pm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: imx@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

---
Haoning CHENG (3):
      dt-bindings: thermal: imx: Document calibration offset property
      thermal/drivers/imx: Fix rounding and clamp for i.MX7D alarm
      thermal/drivers/imx: Add calibration offset support

 .../devicetree/bindings/thermal/imx-thermal.yaml   | 12 +++++++
 drivers/thermal/imx_thermal.c                      | 39 ++++++++++++++++++++--
 2 files changed, 48 insertions(+), 3 deletions(-)
---
base-commit: c50a940dcde35c647e097e89a9150003abd48329
change-id: 20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-a084984deb76

Best regards,
--  
Haoning Cheng <Haoning.CHENG@cn.bosch.com>

