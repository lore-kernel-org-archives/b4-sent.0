From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] reset: support reset for Amlogic A9 SoC
Date: Tue, 14 Jul 2026 02:33:36 +0000
Message-Id: <20260714-a9-reset-v2-0-8df09b2f437c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAACgVWoC/0XMQQrDIBCF4auEWddilJrYVe9RsjA6JgNNLBqkJ
 Xj32kDp8n88vh0SRsIE12aHiJkShbWGODVgZ7NOyMjVBsGF4h1XzGgWMeHGtJUae+9GrhzU+zO
 ip9dB3YfaM6UtxPch5/a7/hD9R3LLOPOus55LPfYXeTPLI0xkzzYsMJRSPji0kEeiAAAA
X-Change-ID: 20260706-a9-reset-9c39e8fdb06d
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783996426; l=1089;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=W2d5QqQKBqxvLWMEJ0hRfu/NSeHdDzwS5lPAkyQg7Fo=;
 b=vmB7Ld+u4rGK8fGznR+ORfIF7/ETmJgoEKJcC42b6lZpNEmrcerdce4ToUseFpWx35+nXD8kF
 FKlm8kGfiIHAtxvzQq+ZEIcd7vrMWrC+ojyyDkzc/wDkwMRsE5Rtos8
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the reset controller compatibles used by the Amlogic A9 SoC, and
add the reset configuration and compatible entry for the Amlogic A9 AO
reset controller, and add reset node for Amlogic A9.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Use standard node name reset-controller.
- Link to v1: https://lore.kernel.org/r/20260709-a9-reset-v1-0-fd7cf039b853@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: reset: amlogic: Add A9 reset compatibles
      reset: amlogic: Add A9 AO reset controller support
      arm64: dts: amlogic: a9: Add reset controller support

 .../bindings/reset/amlogic,meson-reset.yaml        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-a9-reset.h     | 247 +++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi        |  14 ++
 drivers/reset/amlogic/reset-meson.c                |   9 +
 4 files changed, 275 insertions(+)
---
base-commit: 4336e970ec6890fbd424128c352564a9c1dd514a
change-id: 20260706-a9-reset-9c39e8fdb06d

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

