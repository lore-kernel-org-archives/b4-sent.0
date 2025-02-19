From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/4] Add GPIO interrupt support for Amlogic A4 and A5 SoCs
Date: Wed, 19 Feb 2025 15:29:02 +0800
Message-Id: <20250219-irqchip-gpio-a4-a5-v1-0-3c8e44ae42df@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD6ItWcC/x3MQQqAIBBA0avErBtQ04iuEi3EJp2NmUIE4t2Tl
 m/xf4VCmanAOlTI9HDhK3bIcQAXbPSEfHSDEkpLJSfkfLvACX3iC61Ga3ARzggrtZmdhh6mTCe
 //3TbW/sAeJI412QAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739950145; l=903;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=ImNpnsptW8WJoO1olJWkaeTDPYynu8aJPZ10S0NXgBA=;
 b=kBJy8i3DWBxIZsOOmE/IltkEkpIMhPO6n8vGPuyAvcvoNrKq3atiLHkfjy9kjHyRTRrWpPILK
 h7FUOk0a6/lBs1Dqwb5WzEfHSgZMzdE7hoJS3uooL02uyvXMD3vWlA5
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds GPIO interrupt support for Amlogic A4 and A5 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (4):
      dt-bindings: interrupt-controller: Add support for Amlogic A4 and A5 SoCs
      irqchip: Add support for Amlogic A4 and A5 SoCs
      arm64: dts: Add gpio_intc node for Amlogic-A4 SoCs
      arm64: dts: Add gpio_intc node for Amlogic-A5 SoCs

 .../amlogic,meson-gpio-intc.yaml                   |  5 +-
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 21 ++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 12 +++++
 drivers/irqchip/irq-meson-gpio.c                   | 61 ++++++++++++++++++++++
 4 files changed, 98 insertions(+), 1 deletion(-)
---
base-commit: 953913df9c3ab6f496c6facd5aa7fc9f2f847ac2
change-id: 20241213-irqchip-gpio-a4-a5-80c50a1456c4

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

