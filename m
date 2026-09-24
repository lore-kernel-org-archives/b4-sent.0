From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] t7: add some nodes for Amlogc t7.
Date: Thu, 24 Sep 2026 05:51:07 +0000
Message-Id: <20260924-t7-node-new-v2-0-319d3c19b4b2@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEu6tGoC/23MQQ6CMBCF4auQWTtmWhXQlfcwLKAdYBJpSUtQQ
 3p3K2uX/0vet0HkIBzhVmwQeJUo3uXQhwLM2LqBUWxu0KRLumrCpULnLaPjF55qZZXpL7amCvJ
 jDtzLe9ceTe5R4uLDZ8dX9Vv/O6tCQi6Z6jMZ1VF3b6enH8QcjZ+gSSl9AbmULGOoAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790229071; l=1152;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=J2rvWMrWhfMqJAxvspLLK2ASHYw7aRT+eq8Zg90zFtk=;
 b=pk1EoyJAcbEiAZfM1ScQgUu79YaZw6QFQ0zRa71tyYhp1YfLQUuy2vnXEJLl2PpMw0YSbF2ah
 AVsUqKh0ENfDZuNFX3CqSwHkpYIjSzjIQMoEZd0H4WQK5h04/u4geS6
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
Changes in v2:
- Make some modifications according to the Sashiko AI's reviews.
- Link to v1: https://lore.kernel.org/r/20260920-t7-node-new-v1-0-e6e0840c1b0b@amlogic.com

---
Xianwei Zhao (3):
      spi: dt-bindings: amlogic,meson-gx-spicc: add T7 compatible
      dt-bindings: net: meson-dwmac: add T7 support
      arm64: dts: amlogic: add T7 peripheral nodes

 .../bindings/net/amlogic,meson-dwmac.yaml          |  17 +
 .../bindings/spi/amlogic,meson-gx-spicc.yaml       |  13 +-
 .../boot/dts/amlogic/amlogic-t7-a311d2-an400.dts   | 153 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        | 462 +++++++++++++++++++++
 4 files changed, 641 insertions(+), 4 deletions(-)
---
base-commit: a2530c83c458a503e55219966217dfd1c36a385e
change-id: 20260920-t7-node-new-381d1cf5d807

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

