From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] t7: add some nodes for Amlogc t7.
Date: Sun, 20 Sep 2026 08:13:27 +0000
Message-Id: <20260920-t7-node-new-v1-0-e6e0840c1b0b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKiVr2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyMD3RJz3bz8lFTdvNRyXWMLwxTD5DTTFAsDcyWgjoKi1LTMCrBp0bG
 1tQBYuqvEXQAAAA==
X-Change-ID: 20260920-t7-node-new-381d1cf5d807
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789892012; l=971;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=j5RR68P3oFMU6xBWGop7jkyP1ilGJ5YpBYsz7PL+Ntg=;
 b=w/B0pT+84delXXSkn73CrIlYgv9pNMM2ZLKx7STy3fQOX9ZHtHllLscpI1b9THGtFvvaggdmA
 WcW6BtbcpH9ChVWWGPP7xbV8p7rJR0+SleXRefz+oQLdAP4bmA7bW90
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree descriptions for the peripherals on the Amlogic T7
SoC and the T7 A311D2 AN400 board.

Add the Amlogic T7 SPICC compatible to the device tree binding. 
Add the T7 compatible to the Meson DWMAC binding

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      spi: dt-bindings: amlogic,meson-gx-spicc: add T7 compatible
      dt-bindings: net: meson-dwmac: add T7 support
      arm64: dts: amlogic: add T7 peripheral nodes

 .../bindings/net/amlogic,meson-dwmac.yaml          |  14 +
 .../bindings/spi/amlogic,meson-gx-spicc.yaml       |  13 +-
 .../boot/dts/amlogic/amlogic-t7-a311d2-an400.dts   | 155 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 452 +++++++++++++++++++++
 4 files changed, 630 insertions(+), 4 deletions(-)
---
base-commit: a2530c83c458a503e55219966217dfd1c36a385e
change-id: 20260920-t7-node-new-381d1cf5d807

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

