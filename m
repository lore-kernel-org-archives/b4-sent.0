From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v7 0/4] Driver for Apple Z2 touchscreens.
Date: Mon, 24 Feb 2025 12:01:08 +0100
Message-Id: <20250224-z2-v7-0-2746f2bd07d0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHRRvGcC/13PzU7DMAwH8FeZcibIdmK348R7IA6Nk26R2IpaV
 AFT350000TV49/yzx83M6Uxp8m8HG5mTHOe8nAtoXk6GD1311OyOZZsCMgjkre/ZBWQAlObOoi
 mNH6Oqc/fdcjbe8nnPH0N40+dOeNafXBZ+YwWrHqnXlUIIL6eLl3+eNbhYlY+05a0lVAhjajyM
 YQesdkT9yAMxVTiCmGFxMzRxR73xG8JV+ILiY0T7AJK6GBPeEvuh3EhEl0biFtCOe6J/BOC+xZ
 Z31cBDSlh5LAly7L8AbWoL1aTAQAA
X-Change-ID: 20241124-z2-c012b528ea0d
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Neal Gompa <neal@gompa.dev>, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740394875; l=2765;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=IRBOBjOupyewlrDGtPHlu0OHXgrrC2CpFC42RCnOQDE=;
 b=FJOVBRwuAD8k0F5ggHNq+YETM0cbGKs7+eewX3jq6+WWMtPjJpWcJBEFZEgKLsV1iTpN8MLuT
 ltMNgXuBQ2eATILFiJU6bjscMI2ilQ+B90otPxPOj1+8PfHch7EWwhz
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This series adds support for Apple touchscreens using the Z2 protocol.
Those are used as the primary touchscreen on mobile Apple devices, and for the
touchbar on laptops using the M-series chips. (T1/T2 laptops have a coprocessor
in charge of speaking Z2 to the touchbar).

Originally sent as a RFC at https://lore.kernel.org/all/20230223-z2-for-ml-v1-0-028f2b85dc15@gmail.com/
The changes since then mostly address the review feedback, but also
add another machine that has this specific controller.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v7:
- Added a dependency on ARCH_APPLE to prevent potential confusion on x86
- Link to v6: https://lore.kernel.org/r/20250205-z2-v6-0-cc60cbee1d5b@gmail.com

Changes in v6:
- Went back to build_cal_blob returning an allocated buffer, other fixes.
- Link to v5: https://lore.kernel.org/r/20250118-z2-v5-0-6d38b2582169@gmail.com

Changes in v5:
- Added missing \ns, removed 4kb-ish of wasted ram
- Link to v4: https://lore.kernel.org/r/20250115-z2-v4-0-d7361ab16ba0@gmail.com

Changes in v4:
- Dropped another allocation, other fixes.
- Link to v3: https://lore.kernel.org/r/20250112-z2-v3-0-5c0e555d3df1@gmail.com

Changes in v3:
- Tx/Rx buffers used in interrupt handler are now allocated in probe and reused
- Other various style fixes
- Link to v2: https://lore.kernel.org/r/20241128-z2-v2-0-76cc59bbf117@gmail.com

Changes in v2:
- In a separate patch, fixed an issue that prevented the SPI controller
  from using GPIO CS, and as such, moved the hardware quirk to there
- Went back to uploading the firmware in probe() instad of open()
- Other changes addressing the review feedback
- Link to v1: https://lore.kernel.org/r/20241126-z2-v1-0-c43c4cc6200d@gmail.com

---
Sasha Finkelstein (4):
      dt-bindings: input: touchscreen: Add Z2 controller
      input: apple_z2: Add a driver for Apple Z2 touchscreens
      arm64: dts: apple: Add touchbar digitizer nodes
      MAINTAINERS: Add entries for Apple Z2 touchscreen driver

 .../input/touchscreen/apple,z2-multitouch.yaml     |  70 +++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |  27 ++
 arch/arm64/boot/dts/apple/t8103.dtsi               |  19 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |  23 +
 arch/arm64/boot/dts/apple/t8112.dtsi               |  14 +
 drivers/input/touchscreen/Kconfig                  |  13 +
 drivers/input/touchscreen/Makefile                 |   1 +
 drivers/input/touchscreen/apple_z2.c               | 473 +++++++++++++++++++++
 9 files changed, 642 insertions(+)
---
base-commit: b62cef9a5c673f1b8083159f5dc03c1c5daced2f
change-id: 20241124-z2-c012b528ea0d

