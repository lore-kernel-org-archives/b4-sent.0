From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] support for amlogic rtc
Date: Tue, 03 Sep 2024 15:00:44 +0800
Message-Id: <20240903-rtc-v2-0-05da5755b8d9@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABy01mYC/1WMQQ6DIBBFr2JmXRpmaCrtyns0LgigTlKlAUNqD
 HeXuuvy/fz3dkg+sk/wbHaIPnPisFSgSwN2MsvoBbvKQJJuUpMScbUCqbVO44MMKqjPT/QDf8/
 Kq688cVpD3M5oxt/672cUUtyHViqNzpBWnZnfYWR7tWGGvpRyAFKqYPSYAAAA
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725346845; l=1168;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=i8gz704Qm8ya/o5dE5ZS51DTR2abXR44TQSYVdI/Rvs=;
 b=PUa5Yy6NzJIV4PQ0E3FCZ1uWMcAzPrDAK3DadDyPFeWCAyJhZd0yCH21KZg7uBVsNtp/en4hi
 q5T0DfLtl5qCcRhzV271WF0t/jm/Ub6Xg8GeoRYlm6eW6yj2G/j74Y9
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add rtc driver and bindigns for the amlogic A113L2 and A113X2 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Modify bindings clock name and perfect the example.
- Fix some bug in driver, and use dev_err_probe instead of dev_err in probe process.
- Use RTC API to handle calibration.
- Remove unused func and rename driver file name.
- Link to v1: https://lore.kernel.org/r/20240823-rtc-v1-0-6f70381da283@amlogic.com

---
Yiting Deng (3):
      dt-bindings: rtc: Add Amlogic A4 and A5 rtc
      rtc: support for the Amlogic on-chip RTC
      MAINTAINERS: Add an entry for Amlogic RTC driver

 .../bindings/rtc/amlogic,amlogic-rtc.yaml          |  66 +++
 MAINTAINERS                                        |   8 +
 drivers/rtc/Kconfig                                |  12 +
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-amlogic-a4.c                       | 481 +++++++++++++++++++++
 5 files changed, 568 insertions(+)
---
base-commit: 3047c9a740816d5a930c8c741c3932a3544267f2
change-id: 20240823-rtc-127cd8192a13

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

