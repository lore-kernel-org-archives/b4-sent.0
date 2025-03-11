From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v5 0/4] Add GPIO interrupt support for Amlogic A4 and A5
 SoCs
Date: Tue, 11 Mar 2025 11:08:26 +0800
Message-Id: <20250311-irqchip-gpio-a4-a5-v5-0-ca4cc276c18c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACupz2cC/23QzU7DMAzA8VeZcibITux9cOI9EIfUdVtLbCkpq
 kBT3510F4bW49+Sf5Z8dZMW08m97K6u6GyT5UsNfto5GdKlV29tbRcgEAaM3sqnDDb6frTsE/n
 E/gjCkJB4L+Tq4li0s+8b+vZee7DpK5ef240Z1+nKMQQ8bXEzevBRjkqUlELbvabzR+5NniWf3
 QrO4Q4J+00kVESYGwQGaZgfkfiHROBNJFYEVeUAkUOn6RGhe+SwiVBFWojpRPWFjM1/ZFmWX6f
 P8BaFAQAA
To: Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741662508; l=1918;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=6YFlKkmJqvHypt4lt2xcZRr3utLgEQlOW0fxh7lNRnQ=;
 b=3MveDm9G6ntXWpZhH6/St+ViGjIaVCdHUE+6VbXi9dIntkMm4Da3JSu+SLSFPuRx1RdkvfQhy
 0r385KlVEghDWnVwJUNckZRD/te9Ox+CdrYCQ/XHusuCljFuKQB1OSW
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds GPIO interrupt support for Amlogic A4 and A5 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v5:
- Make minor changes of source code according to Thomas's suggestion.
- Link to v4: https://lore.kernel.org/r/20250307-irqchip-gpio-a4-a5-v4-0-d03a9424151b@amlogic.com

Changes in v4:
- Make minor changes for bindings as Conor and Rob suggest.
- Format adjustment of source code according to Thomas's suggestion.
- Link to v3: https://lore.kernel.org/r/20250305-irqchip-gpio-a4-a5-v3-0-1eec70352fea@amlogic.com

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

 .../amlogic,meson-gpio-intc.yaml                   | 19 ++++++++-
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 19 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 12 ++++++
 drivers/irqchip/irq-meson-gpio.c                   | 48 +++++++++++++++++-----
 4 files changed, 86 insertions(+), 12 deletions(-)
---
base-commit: 73e4ffb27bb8a093d557bb2dac1a271474cca99c
change-id: 20241213-irqchip-gpio-a4-a5-80c50a1456c4

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

