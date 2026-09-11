From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 00/10] soc: amlogic: clk-measure: Add support for more SoCs
Date: Fri, 11 Sep 2026 16:28:27 +0800
Message-Id: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKu7o2oC/x2N0QqDMAwAf0XyvEDtQ637lTFG18UtOE1JVAbiv
 6/4eBzc7WCkTAbXZgeljY1lrtBeGsifNL8J+VUZvPPBda3DSZTQJBsugraWIrpg/o6PiZKt1eX
 owxDTs6cQoWaK0sC/c3G7H8cfS9aQVHIAAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789115329; l=2217;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=1VS5ElObVqR4WKXROqPaqb+LeB1gJwIdpIW5IFGGrxA=;
 b=E3+DeB6GV9hFUk8OaEE06kHsbHmsvNlb9k5j5OnWHHmzw333FSBd2uBr+Mkvls08BW/it78qn
 1KzIArLeCE+DQ3f0fI/UQOoysDxV49AHMVuHd5NI1lPSwNhnPXzhZfO
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds clk-measure support for the Amlogic A5, A4, S7,
S7D, S6 and A9 SoCs, listed in the order of their release.

The clock names for the clk-measure channels are kept consistent with
those used by the clock driver as much as possible, making it easier to
identify the relationship between the clk-measure channels and the
corresponding clocks in the clock driver.

This patchset also includes an additional patch to optimize memory usage:

  - soc: amlogic: clk-measure: Optimize CLK_MSR_ID to reduce memory usage

To avoid requiring everyone to spend additional effort on a separate
patchset, I have included it in this series. Please feel free to point
out if this is not appropriate for this series.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (10):
      dt-bindings: soc: amlogic: Add compatible to support more SoCs
      soc: amlogic: clk-measure: Support more measurement channels
      soc: amlogic: clk-measure: Add support for more SoCs
      soc: amlogic: clk-measure: Optimize CLK_MSR_ID to reduce memory usage
      arm64: dts: amlogic: a5: Add clk-measure controller node
      arm64: dts: amlogic: a4: Add clk-measure controller node
      arm64: dts: amlogic: s7: Add clk-measure controller node
      arm64: dts: amlogic: s7d: Add clk-measure controller node
      arm64: dts: amlogic: s6: Add clk-measure controller node
      arm64: dts: amlogic: a9: Add clk-measure controller node

 .../soc/amlogic/amlogic,meson-gx-clk-measure.yaml  |   6 +
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       |   5 +
 drivers/soc/amlogic/meson-clk-measure.c            | 901 ++++++++++++++++++++-
 8 files changed, 935 insertions(+), 2 deletions(-)
---
base-commit: 87e20720aaadf9540c1596b05b93073a99d02258
change-id: 20260710-more-socs-to-support-clk_measure-c826f8ab9e68

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

