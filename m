From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/5] Pinctrl: Add Amlogic pinctrl driver
Date: Thu, 26 Dec 2024 15:57:40 +0800
Message-Id: <20241226-amlogic-pinctrl-v2-0-cdae42a67b76@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHQMbWcC/3WNwQ6CMBBEf4Xs2TXdBUU9+R+GQ9NW2AQoaUmjI
 f13K/Hq8U1m3mwQXRAX4VZtEFySKH4uwIcKzKDn3qHYwsCKG2Ii1NPoezG4yGzWMCKz02e6sLL
 KQlktwT3ltRsfXeFB4urDez9I9E3/uxKhwoZUy21dn4iu91/jaPwEXc75A8+qYYuwAAAA
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735199863; l=2379;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=8b/59hoXnXDAUbIUEYcQ6psWuniloV83ts4PS5yxSSc=;
 b=g7vOqRgzWD6wbJu6ZnJIYzXnuvYrSKYObzaPPRDDncvr3/7T5Uh2NGMiBOE6kG9mOYKexn8bu
 c9P5+f3KiSADr1WYPYvuzAxx620iDH4bbdU8mO1fDqSnc8WFlMx9Ieu
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl driver support for Amloigc SoCs

Base on the previous discussion,
https://lore.kernel.org/r/20241113-a4_pinctrl-v6-0-35ba2401ee35@amlogic.com
The existed meson driver failed to meet the requirement of the current dt-binding.
So we start this new pinctrl driver to solve problem.

The advantage of this version: Once the source file and binding document
are added, adding dts node will be only operation for subsequent Amlogic SoCs
(such as A4, A5).

The code in DTS file is also readable when using GPIO, as below:
reset-gpios = <&gpiob 6 GPIO_ACTIVE_LOW>;

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Some modifications and optimizations were made to bindings according to Rob's suggestions.
- Refined some details on functions node for bindings. 
- Some source code optimizations were made according to Linus's suggestions.
- Add stand API to generic to deal pinmux propertity.
- Add private reg data to deal with for future SoCs.
- Simplified some unused processing (previously used for extension).
- Sync add to MAINTAINERS files.
- Link to v1: https://lore.kernel.org/r/20241211-amlogic-pinctrl-v1-0-410727335119@amlogic.com

---
Xianwei Zhao (5):
      dt-bindings: pinctrl: Add support for Amlogic SoCs
      pinctrl: pinconf-generic: Add API for pinmux propertity in DTS file
      pinctrl: Add driver support for Amlogic SoCs
      arm64: dts: amlogic: a4: add pinctrl node
      MAINTAINERS: Add an entry for Amlogic pinctrl driver

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  155 +++
 MAINTAINERS                                        |    8 +
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |  133 +++
 drivers/pinctrl/Kconfig                            |   18 +
 drivers/pinctrl/Makefile                           |    1 +
 drivers/pinctrl/pinconf-generic.c                  |  130 +++
 drivers/pinctrl/pinconf.h                          |    4 +
 drivers/pinctrl/pinctrl-amlogic.c                  | 1047 ++++++++++++++++++++
 include/dt-bindings/pinctrl/amlogic,pinctrl.h      |   68 ++
 include/linux/pinctrl/pinconf-generic.h            |    4 +
 10 files changed, 1568 insertions(+)
---
base-commit: 4de5110762b94b9978fb8182a568572fb2194f8b
change-id: 20241211-amlogic-pinctrl-22ea61820d0d

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

