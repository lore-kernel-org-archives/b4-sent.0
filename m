From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/5] Add GPIO interrupt support for Amlogic S6 S7 and S7D
Date: Wed, 05 Nov 2025 17:45:31 +0800
Message-Id: <20251105-irqchip-gpio-s6-s7-s7d-v1-0-b4d1fe4781c1@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALscC2kC/x2MMQqAMAwAv1IyG7AFFf2KOGiMmqWtDYhQ+neLc
 MsNdxmUk7DCZDIkfkQl+Cq2MUDX6k9G2auDa11nbduhpJsuiXhGCag96lDZceTNEQ8HEfVQ45j
 4kPcfz0spH7UkiwFoAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762336003; l=1085;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=sBbijhHOp7oCs6GEaRJPgWgOKT9wxzc+e84cgJVXGks=;
 b=UuVuyQFMIsQ/oSHSwOOpFHXycXVt9jeIo5LDQY86D6wNsX39oK3t12F0Q/VZRCTt4n0bXV7N1
 3mKDqs1TIz1D9OIfcbbLOYnmPLW+O2PRBqPqz+vPmG5fj356OCEol4g
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds GPIO interrupt support for Amlogic S6 S7 and S7D SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (5):
      dt-bindings: interrupt-controller: Add support for Amlogic S6 S7 and S7D SoCs
      irqchip: Add support for Amlogic S6 S7 and S7D SoCs
      arm64: dts: Add gpio_intc node for Amlogic S6 SoCs
      arm64: dts: Add gpio_intc node for Amlogic S7 SoCs
      arm64: dts: Add gpio_intc node for Amlogic S7D SoCs

 .../interrupt-controller/amlogic,meson-gpio-intc.yaml         |  3 +++
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi                   | 10 ++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi                   | 10 ++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi                  | 10 ++++++++++
 drivers/irqchip/irq-meson-gpio.c                              | 11 +++++++++++
 5 files changed, 44 insertions(+)
---
base-commit: cb718411c4c05a4a424c2b73790a1648be97a4af
change-id: 20251105-irqchip-gpio-s6-s7-s7d-9eb2ce7fccc6

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

