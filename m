From: Jian Hu <jian.hu@amlogic.com>
Subject: [PATCH v3 0/4] soc: amlogic: clk-measure: add A1 and T7 support
Date: Tue, 21 Apr 2026 16:17:40 +0800
Message-Id: <20260421-clkmsr_a1_t7-v3-0-efc00b0f9e6b@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKUy52kC/3XMQQ6DIBCF4auYWZcGRoraVe/RGEMRdVKRBoxpY
 7h7qfsu/5e8b4doA9kI12KHYDeK5Jcc5akAM+lltIz63IAcFZfiwsz8dDF0WnRrxZoaeVPLnut
 BQL68gh3ofXD3NvdEcfXhc+gb/tY/0IaMM44PVQopsbLqpt3sRzJn4x20KaUvP46grqoAAAA=
X-Change-ID: 20260415-clkmsr_a1_t7-9820984d0af1
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jian Hu <jian.hu@amlogic.com>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776759517; l=1276;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=Kz+3pMMySerYI/J54KnH+TrQYs1a5xtXn+eQ4dPN+Sc=;
 b=87Uj5tJYBxyT81mPVwhTw3g+vaPd1voTESeTuQlrUEWiUyQumNsXr74S/xP5tUaFeLczeJt/x
 FMyEr/5af2bDMGm7SXh++dvdWb7sGxhSTIGZ2t+KJ6syTecpUqhbSjH
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds Amlogic clock measurement support for A1 and T7 SoCs,
including binding updates, driver additions, and device tree enablement.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
Changes in v3:
- Place the clock-measure node after pwm_ao_gh node for t7.
- Link to v2: https://lore.kernel.org/r/20260415-clkmsr_a1_t7-v2-0-02b6314427e6@amlogic.com

Changes in v2:
- Add const for a1 and t7 clock measure table.
- Use b4 to send this series.
- Link to v1: https://lore.kernel.org/all/20260410100329.3167482-1-jian.hu@amlogic.com

---
Jian Hu (4):
      dt-bindings: soc: amlogic: clk-measure: Add A1 and T7 compatible
      soc: amlogic: clk-measure: Add A1 and T7 support
      arm64: dts: meson: a1: Add clk measure support
      arm64: dts: amlogic: t7: Add clk measure support

 .../soc/amlogic/amlogic,meson-gx-clk-measure.yaml  |   2 +
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/meson-a1.dtsi          |   5 +
 drivers/soc/amlogic/meson-clk-measure.c            | 272 +++++++++++++++++++++
 4 files changed, 284 insertions(+)
---
base-commit: 401e5c73eedde8225e87bd11c794b8409248ff41
change-id: 20260415-clkmsr_a1_t7-9820984d0af1

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

