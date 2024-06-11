From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] Pinctrl: A4: Add pinctrl driver
Date: Tue, 11 Jun 2024 13:10:56 +0800
Message-Id: <20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGHcZ2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDMwNz3UST+ILMvOSSohxdExNzEwNjA0NLQ9M0JaCGgqLUtMwKsGHRsbW
 1ABgVCJtcAAAA
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718082657; l=963;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=a1yCcNo00YVw+JbGiKiSn/QHOttjkTM0NAqfh9YXZrA=;
 b=CZCp68RkKk3QYBnZehamSHoVmqDw+Dzifk10pmgVUl0JpV1jociJdPiNpRjHkbrWa+WeSTn9m
 0+CraFm8i7UDbxmz6UALLINVPDDwMSzAmkl8uAHpkYTKEzmUfVrJhRX
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl driver support for Amloigc A4 SoC

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: pinctrl: Add support for Amlogic A4 SoCs
      pinctrl: meson: Add driver support for Amlogic A4 SoCs
      arm64: dts: amlogic: a4: add pinctrl node

 .../bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml |    2 +
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |   36 +
 drivers/pinctrl/meson/Kconfig                      |    6 +
 drivers/pinctrl/meson/Makefile                     |    1 +
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 1163 ++++++++++++++++++++
 .../dt-bindings/gpio/amlogic,a4-aobus-pinctrl.h    |   21 +
 .../dt-bindings/gpio/amlogic,a4-periphs-pinctrl.h  |   93 ++
 7 files changed, 1322 insertions(+)
---
base-commit: 87501b7ca0005c533d770d37e0047a60954d986a
change-id: 20240607-a4_pinctrl-44740301915f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

