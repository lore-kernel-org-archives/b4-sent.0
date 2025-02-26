From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/4] Add GPIO interrupt support for Amlogic A4 and A5
 SoCs
Date: Wed, 26 Feb 2025 13:47:51 +0800
Message-Id: <20250226-irqchip-gpio-a4-a5-v2-0-c55b1050cb55@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAervmcC/22NQQ6CMBBFr0K6dkxbpgZdeQ/DohkGmEQotoZoS
 O9uYe3yveS/v6nEUTipW7WpyKskCXMBe6oUjX4eGKQrrKy2aKypQeKLRllgWCSAR/AOGk1Oe4P
 uQqjKcIncy+eIPtrCo6R3iN/jYzW73XNOW3P9l1sNaKipYUTPaLv+7qdnGITOFCbV5px/BpKph
 bYAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740548891; l=1226;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=W4cG0I6SC0UXlixxjcHeRMiMZh89LfPef6m5P4FVaKM=;
 b=21MSP023vePsJIFViASdvu1jq/DZsq1/wWCZpFg1Gjyj6vbfksgiXFJtl7pyPUeCZ+NDXhfSe
 J9bXHNvSBO/CUOfVCpktz6AZhXdGcPn3xnCRxnAf7AywRA8IazHiP7h
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds GPIO interrupt support for Amlogic A4 and A5 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
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

 .../amlogic,meson-gpio-intc.yaml                   | 13 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 21 +++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 12 +++++++
 drivers/irqchip/irq-meson-gpio.c                   | 42 +++++++++++++++++++---
 4 files changed, 83 insertions(+), 5 deletions(-)
---
base-commit: 953913df9c3ab6f496c6facd5aa7fc9f2f847ac2
change-id: 20241213-irqchip-gpio-a4-a5-80c50a1456c4

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

