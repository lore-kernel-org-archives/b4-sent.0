From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v6 0/3] support for amlogic rtc
Date: Tue, 12 Nov 2024 11:10:13 +0800
Message-Id: <20241112-rtc-v6-0-a71b60d2f354@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABbHMmcC/2XQTY7CMAwF4KugrCcj20mahBX3GLFwkxQiDRSlq
 BqEevdJAfGjLp/l78nyVQyp5DSI9eoqShrzkPtjDc3XSoQ9H3dJ5lizICANjpQs5yCRbIgOPTE
 qUTdPJXX579bys615n4dzXy630hHn6acfUYJsOgvKYWRyasOH336Xw3foD2JuGOmlPDwUVQUms
 rHGtC76pVJvCuGuVFXYMVjLjWeCpdJvih5KV+WRk+lanVQ0S2WeChHcXZn5QvTa1gdZ69pPNU3
 TP2F2bv9wAQAA
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731381015; l=1965;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=8+WX5Wakdt4EUxqtzq8N3biWqhl54KfXtJQv1VX3/4Y=;
 b=TANdTkttCYRYPNirhoyhhJut9zf+qam2b1+ZjxF92JQSH8rIvnasgBpPHoyIZ/AF/oGS8QHw2
 i8JZX2q3orfCBqLQ8lP46a687tVDlH0RIl7c0nLfNOycuwips6tZZvm
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add rtc driver and bindigns for the amlogic A4(A113L2) and A5(A113X2) SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v6:
- Solve compilation problems and dropped disable rtc action in remove funcion.
- Link to v5: https://lore.kernel.org/r/20241108-rtc-v5-0-0194727c778b@amlogic.com

Changes in v5:
- Some formatting adjustments and minor fixes were made based on Christophe's suggestions.
- Link to v4: https://lore.kernel.org/r/20240920-rtc-v4-0-91ae5fb4e3d5@amlogic.com

Changes in v4:
- Keep the same order as as in properties.
- Link to v3: https://lore.kernel.org/r/20240910-rtc-v3-0-1fa077a69a20@amlogic.com

Changes in v3:
- Perfect the binding description and rename binding.
- Using dev_err_probe function correctly, and modify commit message.
- Change placement about MAINTAINERS.
- Link to v2: https://lore.kernel.org/r/20240903-rtc-v2-0-05da5755b8d9@amlogic.com

Changes in v2:
- Modify bindings clock name and perfect the example.
- Fix some bug in driver, and use dev_err_probe instead of dev_err in probe process.
- Use RTC API to handle calibration.
- Remove unused func and rename driver file name.
- Link to v1: https://lore.kernel.org/r/20240823-rtc-v1-0-6f70381da283@amlogic.com

---
Yiting Deng (3):
      dt-bindings: rtc: Add Amlogic A4 and A5 RTC
      rtc: support for the Amlogic on-chip RTC
      MAINTAINERS: Add an entry for Amlogic RTC driver

 .../devicetree/bindings/rtc/amlogic,a4-rtc.yaml    |  63 +++
 MAINTAINERS                                        |   8 +
 drivers/rtc/Kconfig                                |  12 +
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-amlogic-a4.c                       | 474 +++++++++++++++++++++
 5 files changed, 558 insertions(+)
---
base-commit: 8a2c49e0fd92e6760636bcfbf11e11d9ddd61cf9
change-id: 20240823-rtc-127cd8192a13

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

