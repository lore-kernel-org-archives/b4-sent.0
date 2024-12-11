From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH RFC 0/3] Pinctrl: Add Amlogic pinctrl driver
Date: Wed, 11 Dec 2024 14:47:48 +0800
Message-Id: <20241211-amlogic-pinctrl-v1-0-410727335119@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJQ1WWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDI0ND3cTcnPz0zGTdgsy85JKiHF0jo9REM0MLI4MUgxQloK6CotS0zAq
 widFKQW7OSrG1tQCTIDtuZgAAAA==
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733899686; l=1432;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=OXcuGUST6PRMVKw++DvXhy9nNIvoCMMSwx2WhM7mMpE=;
 b=FCAXcPi+2/pdauQ4NMuHxESiRUOmogABmpyrp0hwKtO3ielhPDS+1E/wKrJ4TTlFKTKZDGwDt
 um+UAOvzQjIDnQFdm51p4MCGAvMyKCjf+u4yv8ye9qDZAgNmUxQiOuK
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
Xianwei Zhao (3):
      dt-bindings: pinctrl: Add support for Amlogic SoCs
      pinctrl: Add driver support for Amlogic SoCs
      arm64: dts: amlogic: a4: add pinctrl node

 .../bindings/pinctrl/amlogic,pinctrl.yaml          |  150 +++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |  146 +++
 drivers/pinctrl/Kconfig                            |   18 +
 drivers/pinctrl/Makefile                           |    1 +
 drivers/pinctrl/pinctrl-amlogic.c                  | 1190 ++++++++++++++++++++
 include/dt-bindings/pinctrl/amlogic,pinctrl.h      |   68 ++
 6 files changed, 1573 insertions(+)
---
base-commit: 171aa289a6fe65faffeb92a1fda283c055435a62
change-id: 20241211-amlogic-pinctrl-22ea61820d0d

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

