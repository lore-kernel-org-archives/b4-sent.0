From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/4] Add GPIO interrupt support for Amlogic A4 and A5
 SoCs
Date: Wed, 05 Mar 2025 18:02:55 +0800
Message-Id: <20250305-irqchip-gpio-a4-a5-v3-0-1eec70352fea@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFAhyGcC/23NQQ6CMBCF4auQrh3Tlg5BV97DuChDgUnEYmsaD
 eHuFlaasPxfMt/MIrrALopzMYvgEkf2jxzloRA02EfvgNvcQkttlFYlcHjSwBP0E3uwBixCLQm
 lVQYrMiIfTsF1/N7Q6y33wPHlw2f7kdS6rhxKrU57XFIgoaTaGWOd0W13sePd90xH8qNYwaR/E
 F3tIjojhNgoiZIaxH9kWZYvB3S4ZfsAAAA=
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741168977; l=1486;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=1g440IuVdvferMaa49XKcEufmSsf3xpIra5Mss3ih/M=;
 b=v148/pWMVfxrubeqy83sCyRkyelbM2gzK8tehnIW/gbWJObeuEoCq0Zbc/PIJGm6f6FC/EJx/
 AAG597zMpDNCrYpX6lGmZxdULCQv8lP/YooM/tKmazoT/14nKoPXuVZ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds GPIO interrupt support for Amlogic A4 and A5 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Fix warning when run 'make ARCH=arm64 dtbs_check'.
- Fix warning when run 'make ARCH=arm64 Image W=1'.
- Rebase file amlogic-a4.dtsi.
- Link to v2: https://lore.kernel.org/r/20250226-irqchip-gpio-a4-a5-v2-0-c55b1050cb55@amlogic.com

Changes in v2:
- Use if/then instead of direct modification minimum value for property 'amlogic,channel-interrupts'.
- Add register offsets to the parameter structure to reduce definition of a function.
- Link to v1: https://lore.kernel.org/r/20250219-irqchip-gpio-a4-a5-v1-0-3c8e44ae42df@amlogic.com

---
Xianwei Zhao (4):
      dt-bindings: interrupt-controller: Add support for Amlogic A4 and A5 SoCs
      irqchip: Add support for Amlogic A4 and A5 SoCs
      arm64: dts: Add gpio_intc node for Amlogic A4 SoCs
      arm64: dts: Add gpio_intc node for Amlogic A5 SoCs

 .../amlogic,meson-gpio-intc.yaml                   | 21 ++++++++++--
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 19 ++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 12 +++++++
 drivers/irqchip/irq-meson-gpio.c                   | 40 +++++++++++++++++++---
 4 files changed, 85 insertions(+), 7 deletions(-)
---
base-commit: 73e4ffb27bb8a093d557bb2dac1a271474cca99c
change-id: 20241213-irqchip-gpio-a4-a5-80c50a1456c4

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

