From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Subject: [PATCH v6 0/2] Add support for the DFRobot SD2405AL I2C RTC
 Module.
Date: Thu, 29 Aug 2024 13:31:43 +0200
Message-Id: <20240829-rtc-sd2405al-v6-0-4fbfe2624aa7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAB9c0GYC/3XMy2pDIRSF4VcJjmvRrdtLR32P0sH2lghJTtFwa
 Ann3Wsy6UHo8F/wrTvrudXc2dvhzlpea6/LdYR5ObB4ousx85pGMxCghRGWt1vkPY1AOnMSXlt
 lbbQqsUG+Wi71+3n38Tn6VPttaT/P91U+1n+OVsklR4XeymzJGfN+vFA9v8blwh5HK+yw9BOGg
 ZUPmcCHBIQzVjsMYsJqYIMJQxCSCooZ6z3WE9YDQ4AQLfriXZkx/mEHbsLIBfdZFVcIM5mwx9u
 2/QLvNL/xnAEAAA==
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-rtc@vger.kernel.org, 
 csokas.bence@prolan.hu, devicetree@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724931117; l=2200;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=uYxpjHp9Ljf845Tzrl395BhPRS0C3P+4ZbcnfLa0518=;
 b=+6ciJKwZqbyFv342MwIvlx2S8zq7YDYGcrHQwIIiGxQu6/LipLy0u+BPGryhDAXy1iHaN/h4Y
 nGppAMpYNUgAfpfSdMZ5d4igjME1VmgFu55V0FKDqyWnGUXBQSIrTXr
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds a driver and the documentation for the SD2405AL I2C RTC.

To: Alexandre Belloni <alexandre.belloni@bootlin.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org
Cc: linux-rtc@vger.kernel.org
Cc: csokas.bence@prolan.hu
Cc: devicetree@vger.kernel.org
Signed-off-by: Tóth János <gomba007@gmail.com>

Changes in v6:
- Add missing To-s and Cc-s.
- Rebased onto v6.11-rc5
- Link to v5: https://lore.kernel.org/r/20240828-rtc-sd2405al-v5-0-9e3f8fa5ea6b@gmail.com

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
base-commit: 5be63fc19fcaa4c236b307420483578a56986a37
change-id: 20240607-rtc-sd2405al-a0947377c73d

Best regards,
-- 
Tóth János <gomba007@gmail.com>

