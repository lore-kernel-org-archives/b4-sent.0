From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Subject: [PATCH v8 0/3] thermal: imx: Add calibration offset support
Date: Tue, 14 Jul 2026 18:28:40 +0800
Message-Id: <20260714-b4-symana21-11221-imx-thermal-support-upstream-6-18-v8-0-d54d8690e16e@cn.bosch.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFgPVmoC/63SyWrDMBQF0F8JWldB85BV/6N0IclPtUo9INkmI
 eTfKyebULxKvRFceOhcpHdFBXKCgk6HK8qwpJKGvgbzdkChdf0X4NTUjBhhimhisRe4XDrXO0Y
 xpayeqTvjqYXcuR9c5nEc8oTnsUwZXIcVpgY7YoQ1ogGvFao3jxliOt/Vj89HLrP/hjCt1DrRp
 jIN+XKvtdB17n8NFooJJiQaEwWznPj30B/9UEJ7DEOH1hIL24FhDyZqJqwEJjYY/sRQ8hrDK9N
 4GwOzQgcpNxixAyMqQyNEqxsatCQbjHxm+GuMrIyygsjAiQpq62/UDoyqjDGOaxMdBLf1aHoHR
 q8rYL2qu66sB/qHud1uvwK4PZx1AwAA
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
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784024921; l=5106;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=CBpaQr5fKCtCP+D9Xse02LIAN+vOPSrGcX40hnCPS14=;
 b=OQT3KHxAhiSG0hrrgik3MncSWesBrq63j2XMmBphBM5fcyCje6Peb/xYIznzH6NwFFW+hAW7g
 vNt6RaYakCWAcMlJTFxvalEnABh18BFDUvaZvQo9JZDoNFC/9Bo6tRF
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some i.MX boards need a small per-design correction to align the
reported CPU temperature with board-level measurements. This series
adds an optional DT property to specify such a calibration offset
and implements the corresponding support in the imx_thermal driver.

Patch 1 documents the new fsl,temp-calibration-offset-millicelsius
property in the i.MX thermal DT binding. The range is limited to
±20 °C because a temperature sensor with such a high deviation
would be unusable.

Patch 2 fixes the i.MX7D alarm temperature conversion to use
ceiling division (DIV_ROUND_UP() for non-negative, plain /
for negative) and clamp() to stay within the 9-bit register range.

Patch 3 reads this property in the imx_thermal driver and applies
the offset to the i.MX6/6SX/7D calibration formulas. Out-of-range
values are rejected with -EINVAL at probe time. When the property
is absent, the default offset remains 0, preserving the current
behavior.

Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
---
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

 .../devicetree/bindings/thermal/imx-thermal.yaml   | 11 ++++++
 drivers/thermal/imx_thermal.c                      | 39 ++++++++++++++++++++--
 2 files changed, 47 insertions(+), 3 deletions(-)
---
base-commit: c50a940dcde35c647e097e89a9150003abd48329
change-id: 20260709-b4-symana21-11221-imx-thermal-support-upstream-6-18-a084984deb76

Best regards,
--  
Haoning CHENG <Haoning.CHENG@cn.bosch.com>

