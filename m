From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] irqchip: Add GPIO interrupt support for Amlogic A9
Date: Fri, 08 May 2026 07:36:53 +0000
Message-Id: <20260508-a9-gpio-irqchip-v1-0-9dc5f3e022e0@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJWS/WkC/x3MQQqAIBBA0avIrBswKcuuEi1Ep5pNmkIE4t2Tl
 m/xf4FMiSnDIgokejhzuBr6ToA77XUQsm8GJZWWo5zRGjwiB+R0u5Mj+kmrfiBnnPbQqpho5/c
 /rlutHzYDPXxhAAAA
X-Change-ID: 20260508-a9-gpio-irqchip-d76214ec9c6d
To: Thomas Gleixner <tglx@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778225816; l=772;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=A1soFdD0r4US6yDMTZRbjriVCP7JZmrk16cvvRa11AQ=;
 b=PUTdu/0oehvaqyiIMJg5q4YOtOBv59FaV+RpC//iZQ+5aZeSr4vf6dcdVuwfqIsiVqReLzPDw
 OKi3Ww8/M0fBXQg4RCaMvXhk4co7hps3vShnklLRi4S2usQtF9OByqP
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix one error about reg address when set irq type for S4.

Add string of bindings and driver to support A9 GPIO interrupt.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      irqchip/meson-gpio: fix incorrect register address
      dt-bindings: interrupt-controller: Add support for Amlogic A9 SoCs
      irqchip/meson-gpio: Add support for Amlogic A9 SoCs

 .../amlogic,meson-gpio-intc.yaml                   | 21 ++++--
 drivers/irqchip/irq-meson-gpio.c                   | 78 +++++++++++++++++++++-
 2 files changed, 93 insertions(+), 6 deletions(-)
---
base-commit: 8b379d5e9eb7933c73e77e768d95f11ef2833c26
change-id: 20260508-a9-gpio-irqchip-d76214ec9c6d

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

