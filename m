From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Subject: [PATCH 0/6] arm64: dts: imx8mq-librem5: Various improvements for
 Librem 5
Date: Mon, 05 Jan 2026 21:39:37 +0100
Message-Id: <20260105-l5-dtb-fixes-v1-0-f491881a7fe7@puri.sm>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIkhXGkC/x3MQQrCQAyF4auUrA2mhVbGq4iLzDTaQB0laUUov
 bvR5cfjfxu4mIrDudnA5K2uzxpoDw2UietdUMcwdNQN1FKPc4/jkvGmH3EsnAbJKRGVE0TyMvk
 PUVyu4cwumI1rmX4ns9bVjw/2RQz2/Qsz70gwfQAAAA==
X-Change-ID: 20260105-l5-dtb-fixes-ca96eb9900c7
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kernel@puri.sm, Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>, 
 Denis Sergeevich <galilley@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1047;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=h1l9P7NkAKNJ+XD9BctiE5OChOQI9lTMcTs+NJRvzLI=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpXCGgxphxkK6Aiw/QlxhgE83NF6pMFn9DuKqeI
 qoUnWOJCjCJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVwhoAAKCRDo8jXPO9vD
 /+P/D/0Yw7W5ptdqIAPyLsNULtdCV2DUmIpYdm5blfamHr1H20WTIoNAsFalOpCfyXZcpnMUk3q
 m9YoMsEfQJlxGo3ysQMap3QuO32IhD+StUSkHVyteNbTuT0MKOYWjcH/Sdr5U/7Vq1Dfien7aZv
 Cl2/zqW2hLswCdS5hIfcJtLTiNJhDkRPtg7O1NV+VgQltp4UogA1/+WCkZ8AzRGRNvQw94UsitQ
 lWx3ti+NqCH9MfLqHmZIFUCOa+eKIL8PYkd04WRmpL8DRAoCGmMqtDYKz0NoaCiEDmm8bsmM+1Q
 Ol3XWNdu0tA6ej8b/EOGyaQsI0V4p5B5E+j/LOoc1xlMKpX1JMH6nZWfv0WFsBBtzhwXix1G5Rz
 y8G3HX619aSedWM8S9sngPJbkJJN2UhNZtYTxW/UHMvEkTqhYvSyGLJ9vYj+Q/uXyG/DD8fzui7
 fn4tT3fx2bAbYY0zAQtA59vulOJDmvIefkdzTUUWKJ6Vysq/Q/XIy/kshfgoNDrmLtD6GOL21vv
 BBL9H+jZqa4lNoixAgpERI8Kcb4zaED0aYl34ao0pbWmjw3zuNAIZ5dLGWGWTOt2XutGVhbTLik
 kPR6IWj7AMmm3q+mkm44hui7jFZBzCW2PAQYnXD6dCWk+oPOCpdjnPnHdt/psxSnWFx8AnKZGne
 piWwewzgdNue6HA==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are various DTS patches collected over time in Purism's
downstream tree - fixing the vibrator's PWM, improving reliability
of SparkLAN WiFi card and I2C buses, enabling power-on on RTC alarm
and cleaning up an unneeded property.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
Sebastian Krzyszkowiak (6):
      arm64: dts: imx8mq-librem5: Enable I2C recovery
      arm64: dts: imx8mq-librem5: Set vibrator's PWM frequency to 20kHz
      arm64: dts: imx8mq-librem5: Enable SNVS RTC
      arm64: dts: imx8mq-librem5: Limit uSDHC2 frequency to 50MHz
      arm64: dts: imx8mq-librem5: Set cap-power-off-card for usdhc2
      arm64: dts: imx8mq-librem5: Don't set mic-cfg for wm8962

 arch/arm64/boot/dts/freescale/imx8mq-librem5.dtsi | 67 ++++++++++++++++++-----
 1 file changed, 54 insertions(+), 13 deletions(-)
---
base-commit: 9ace4753a5202b02191d54e9fdf7f9e3d02b85eb
change-id: 20260105-l5-dtb-fixes-ca96eb9900c7

Best regards,
-- 
Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>

