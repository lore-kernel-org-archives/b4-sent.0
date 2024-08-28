From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Subject: [PATCH v5 0/2] Add support for the DFRobot SD2405AL I2C RTC
 Module.
Date: Wed, 28 Aug 2024 10:22:53 +0200
Message-Id: <20240828-rtc-sd2405al-v5-0-9e3f8fa5ea6b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAF3ezmYC/3XMSwrCMBSF4a1IxkaSm9zGOHIf4iCvtgG1kpSil
 O7dtKMScPgf+M5MckgxZHI5zCSFKeY4vErg8UBcb15doNGXJsBAsoYpmkZHsy+B5kEN01IJpZw
 SnhTyTqGNn+3udi/dxzwO6bu9T3xd/xxNnHKKArXiQZlz01y7p4mPkxueZD2aYIe5rjAULLQNB
 rT1YLDGYoeBVVgU3KBHaxk3LbIayz2WFZYFgwXrFOpWn9s9XpblBzh3HTxfAQAA
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-kernel@vger.kernel.org, linux-rtc@vger.kernel.org, 
 csokas.bence@prolan.hu, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724833402; l=1737;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=YOUO7QM/mNFv4GCdn4obTvUaMSnLjQC1ZvasM2TWqgY=;
 b=wJaZc3Hdr/W8uvJV1RFhkf1rN1QdEsmIgtL/RD2TYNpPiih2C9lEqle1AtjpI+XmpY2OmtMvD
 MD4vyvcusd/CVsUBkoSgf4jkZ3SC5YVI7lIUhDQyYTQf7x+aBA7ss99
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds a driver and the documentation for the SD2405AL I2C RTC.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
Changes in v5:
- Rework based on Alexandre Belloni's suggestions.
- Drop explicit initialization of struct i2c_device_id::driver_data.
- Add documentation.
- Link to v4: https://lore.kernel.org/r/20240624-rtc-sd2405al-v4-1-2b2bc759f98f@gmail.com

Changes in v4:
- Implement more comprehensive data validation.
- Inline some temporary variables.
- Link to v3: https://lore.kernel.org/r/20240620-rtc-sd2405al-v3-1-65d5bb01af50@gmail.com

Changes in v3:
- #define-s of registers are reworked.
- Minor revisions based on the reviewer's suggestions.
- Link to v2: https://lore.kernel.org/r/20240619-rtc-sd2405al-v2-1-39bea29bd2a5@gmail.com

Changes in v2:
- Refactored based on reviewer's suggestions.
- I couldn't get the I2C IRQ to work on Raspberry Pi 4, so alarm is
  skipped.
- Link to v1: https://lore.kernel.org/r/20240607-rtc-sd2405al-v1-1-535971e7a866@gmail.com

---
Tóth János (2):
      drivers: rtc: Add driver for SD2405AL.
      dt-bindings: rtc: Add support for SD2405AL.

 .../devicetree/bindings/rtc/trivial-rtc.yaml       |   2 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   6 +
 drivers/rtc/Kconfig                                |  10 +
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-sd2405al.c                         | 227 +++++++++++++++++++++
 6 files changed, 248 insertions(+)
---
base-commit: c3f38fa61af77b49866b006939479069cd451173
change-id: 20240607-rtc-sd2405al-a0947377c73d

Best regards,
-- 
Tóth János <gomba007@gmail.com>

