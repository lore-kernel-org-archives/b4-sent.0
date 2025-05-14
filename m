From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/8] Add support for Amlogic S7/S7D/S6 pinctrl
Date: Wed, 14 May 2025 15:01:27 +0800
Message-Id: <20250514-s6-s7-pinctrl-v1-0-39d368cad250@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMc/JGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDU0MT3WIz3WJz3YLMvOSSohzdxDTD1KSURAuLRJNUJaCegqLUtMwKsHn
 RsbW1ADAKQIJfAAAA
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747206100; l=1883;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=UCvwzxK/bPYbO8uWFcLJf6fdSxKUc+Dc5+81ionsKhM=;
 b=9zDdZ22pvS5vNX0fUz5ZoCaN6HYJO/cDbnhKPhZi+P2y4KnpF3VzjKvUGxtZryG6WooZyc0AW
 PV4rUrCHdZXBqRMOSsRbuUQorKcwea07dQkxMWVfTTRUIFci2gJQl/k
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some Amlogic SoCs, to save register space or due to some
abnormal arrangements, two sets of pins share one mux register.
A group starting from pin0 is the main pin group, which acquires
the register address through DTS and has management permissions,
but the register bit offset is undetermined.
Another GPIO group as a subordinate group. Some pins mux use share
register and bit offset from bit0 . But this group do not have
register management permissions.

In SoC S7 and S7D, GPIOX(16~19) mux share with GPIOCC mux register.

In SoC S6, GPIOX(16~19) mux share with GPIOCC mux register, and GPIOD(6)
mux share with GPIOF mux register.

Add S7/S7D/S6 pinctrl compatible string and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (8):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for S7
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for S7D
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for S6
      pinctrl: meson: a4: remove special data processing
      pinctrl: meson: support amlogic S6/S7/S7D SoC
      dts: arm64: amlogic: add S7 pinctrl node
      dts: arm64: amlogic: add S7D pinctrl node
      dts: arm64: amlogic: add S6 pinctrl node

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |   9 +-
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        |  97 ++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        |  81 +++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       |  90 +++++++++++++++++
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 111 ++++++++++++++++-----
 5 files changed, 363 insertions(+), 25 deletions(-)
---
base-commit: aa94665adc28f3fdc3de2979ac1e98bae961d6ca
change-id: 20250514-s6-s7-pinctrl-af1ebda88a4e

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

