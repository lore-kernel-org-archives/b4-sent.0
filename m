From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v6 0/5] Pinctrl: A4: Add pinctrl driver
Date: Wed, 13 Nov 2024 15:29:38 +0800
Message-Id: <20241113-a4_pinctrl-v6-0-35ba2401ee35@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGJVNGcC/2XP0QqCMBTG8VeRXbfY5tFZV71HRKyzow7UxYxRh
 O/eDCLFy2/w+3P2ZiMFRyM7Zm8WKLrR+SGNcpcxbM3QEHc2baaEAimk4gaudzfgI3RcHKy8KSM
 1gWYJ3APV7vmNnS9pt258+PD6tqOaX38ZWGai4oLnpMGUBaqqoJPpO9843KPv2RyK+RJXK5wnT
 LqsrcRaSKu3GP446RWGGdf2UJHF3FjY4mKB17+PxXw2lAJJCoRKrPE0TR/FIPJkXQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731482979; l=3167;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=jTZlTZlZlc/8oe7tDDpKMU27TjCaQVXWIYr+dhvV8jI=;
 b=m4K96oRnL5/UOrRY29MRVvvw544CUEkerxoU9h9+7gESaPC+1p4F26yp8bt0b3sdQ+/DisqvJ
 TQPy19ewAEQCS6TZcCKjgOP75oiW4iuhjTXIynPf891+IeErHIFnSoj
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl driver support for Amloigc A4 SoC

All of Amogic SoCs GPIO device requirement is met here by
adding GPIO bank definition instead of the pin definition.
Binding header files will no longer be added to future
SoCs's pin devices.

The pinctrl software only adds insterface of of_xlate to support
for transformation without affecting the overall framework and
is compatible with previous drivers.

The code in DTS file is also readable when using GPIO, as below:

reset-gpios = <&gpio AMLOGIC_GPIO_X 6 GPIO_ACTIVE_LOW>;

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v6:
- Adjust code formatting and style.
- Remove "#gpio-cells" definition from amlogic,meson-pinctrl-common.yaml
  and add them in all amlogic,meson-pinctrl-XXX.yaml with const: 2, and then
  add amlogic,meson-pinctrl-a4.yaml(copy form  amlogic,meson-pinctrl-a1.yaml) with const: 3.
- Link to v5: https://lore.kernel.org/r/20241112-a4_pinctrl-v5-0-3460ce10c480@amlogic.com

Changes in v5:
- Modify if to switch.
- Dropped parameter combination, bank and offset as independent parameter passing
- Link to v4: https://lore.kernel.org/r/20241101-a4_pinctrl-v4-0-efd98edc3ad4@amlogic.com

Changes in v4:
- Add interface of of_xlate support.
- Add const for some variable.
- Link to v3: https://lore.kernel.org/r/20241018-a4_pinctrl-v3-0-e76fd1cf01d7@amlogic.com

Changes in v3:
- Remove head file from binding.
- Move GPIO define to file *.c.
- Link to v2: https://lore.kernel.org/r/20241014-a4_pinctrl-v2-0-3e74a65c285e@amlogic.com

Changes in v2:
- Use one marco instead of all pin define.
- Add unit name for dts node.
- Link to v1: https://lore.kernel.org/all/20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com/

---
Xianwei Zhao (5):
      dt-bindings: pinctrl: move gpio-cells property
      dt-bindings: pinctrl: Add support for Amlogic A4 SoCs
      pinctrl: meson: add interface of of_xlate
      pinctrl: meson: Add driver support for Amlogic A4 SoCs
      arm64: dts: amlogic: a4: add pinctrl node

 .../bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml |    3 +
 .../bindings/pinctrl/amlogic,meson-pinctrl-a4.yaml |   80 ++
 .../pinctrl/amlogic,meson-pinctrl-common.yaml      |    3 -
 .../pinctrl/amlogic,meson-pinctrl-g12a-aobus.yaml  |    3 +
 .../amlogic,meson-pinctrl-g12a-periphs.yaml        |    3 +
 .../pinctrl/amlogic,meson8-pinctrl-aobus.yaml      |    3 +
 .../pinctrl/amlogic,meson8-pinctrl-cbus.yaml       |    3 +
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |   36 +
 drivers/pinctrl/meson/Kconfig                      |    6 +
 drivers/pinctrl/meson/Makefile                     |    1 +
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 1324 ++++++++++++++++++++
 drivers/pinctrl/meson/pinctrl-meson.c              |    4 +
 drivers/pinctrl/meson/pinctrl-meson.h              |    4 +
 include/dt-bindings/gpio/amlogic-gpio.h            |   45 +
 14 files changed, 1515 insertions(+), 3 deletions(-)
---
base-commit: 58e2d28ed28e5bc8836f8c14df1f94c27c1f9e2f
change-id: 20241012-a4_pinctrl-09d1b2a17e47

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

