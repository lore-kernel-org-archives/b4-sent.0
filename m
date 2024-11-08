From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v5 0/3] support for amlogic rtc
Date: Fri, 08 Nov 2024 13:54:40 +0800
Message-Id: <20241108-rtc-v5-0-0194727c778b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKCnLWcC/2XMQQrCMBCF4atI1kZmJk2TuPIe4mKapBpQK6kUp
 fTuRi2ouHzDfP8o+phT7MV6MYoch9Sn7lyGXi6EP/B5H2UKZQsCqsCSkvnqJZLxwaIjRiXK5yX
 HNt1ele2u7EPqr12+v6IDPq+/fkAJsm4NKIuByaoNn47dPvmV707iWRjooxzMiooCHVgbrRsb3
 L9SXwrhrVRR2DIYw7Vjgn9VfSmaVVWUQ466baqogv5V0zQ9AHxC7B46AQAA
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731045288; l=1783;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Y4CwMwPQuIcU9wjKisRuEikA8yK46OIFjAflX16ws80=;
 b=jNGWNeJoco9mLfZbzE2NrkqAIYDH1CSdtYucDI0JEHejYpvcKvY4w66zcRCS9Mb/K3YCtBcUj
 hkfwvRfI3bkB02bbKqR3yXYI6kKWxsGkcNT9ClwgDaq+OXPLCFZvPrc
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add rtc driver and bindigns for the amlogic A4(A113L2) and A5(A113X2) SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
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
 drivers/rtc/rtc-amlogic-a4.c                       | 476 +++++++++++++++++++++
 5 files changed, 560 insertions(+)
---
base-commit: 8a2c49e0fd92e6760636bcfbf11e11d9ddd61cf9
change-id: 20240823-rtc-127cd8192a13

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

