From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 00/13] soc: amlogic: clk-measure: Add more SoCs to support
 clk-measure
Date: Fri, 15 Aug 2025 16:37:26 +0800
Message-Id: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMfxnmgC/x2N0QrCMAwAf2Xk2UDXWUR/RURiGzXolpJsIoz9u
 8XH4+BuBWcTdjh1Kxh/xEWnBv2ug/yk6cEopTHEEFM4DD1SKTiqMbpmx1nRl1rVZszv13Vk8qW
 5W6T9kI6hJCJoqWp8l+9/c75s2w/yQ+LWdgAAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755247056; l=2630;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=L7VZdGs5j0iAIIVV95ydOPA+CQ4L5Vw5Pc4ESRH7W5A=;
 b=HrV4mTTd9v5hmPvd3ShYi4GdXeIZDlANBSxOzuM4gM9XilonMTDwDrW+DuLRkddH2wFDdyUbj
 9cbdHjUfK2FAS1fSwzBLSODvtHVd+QKD31ItH7oLe9+kRlH/BVEwSch
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As support for clk-measure expands across more SoCs, the current
approach of defining all SoC-specific clk-measure table data in the
driver .c file results in progressively larger compiled images,
resulting in memory wastage.

Move SoC-specific clk-measure tables to DTS definitions and extend
support for additional SoCs (A4, A5, S7, S7D and S6).

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Chuan Liu (13):
      dt-bindings: soc: amlogic: Add clk-measure related properties
      soc: amlogic: clk-measure: Remove the msr_data from clk-measure
      ARM: dts: amlogic: add clk-measure IDs and names for meson SoC family
      arm64: dts: amlogic: add clk-measure IDs and names for Amlogic SoCs
      dt-bindings: soc: amlogic: Unify the compatible property for clk-measure
      soc: amlogic: clk-measure: Unify the compatible property
      ARM: dts: amlogic: Unify the compatible property for clk-measure
      arm64: dts: amlogic: Unify the compatible property for clk-measure
      arm64: dts: amlogic: A4: Add clk-measure controller node
      arm64: dts: amlogic: A5: Add clk-measure controller node
      arm64: dts: amlogic: S7: Add clk-measure controller node
      arm64: dts: amlogic: S7D: Add clk-measure controller node
      arm64: dts: amlogic: S6: Add clk-measure controller node

 .../soc/amlogic/amlogic,meson-gx-clk-measure.yaml  |  66 +-
 arch/arm/boot/dts/amlogic/meson8.dtsi              |  94 ++-
 arch/arm/boot/dts/amlogic/meson8b.dtsi             |  94 ++-
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 212 +++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 202 +++++
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        | 275 +++++-
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        | 312 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        | 253 ++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       | 243 ++++++
 arch/arm64/boot/dts/amlogic/meson-axg.dtsi         | 144 +++-
 arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi  |   2 +-
 arch/arm64/boot/dts/amlogic/meson-g12a.dtsi        | 229 +++++
 arch/arm64/boot/dts/amlogic/meson-gx.dtsi          | 136 ++-
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 301 ++++++-
 arch/arm64/boot/dts/amlogic/meson-sm1.dtsi         | 255 +++++-
 drivers/soc/amlogic/meson-clk-measure.c            | 930 ++-------------------
 16 files changed, 2877 insertions(+), 871 deletions(-)
---
base-commit: e5624eb63c452efa753759e74eb27fe132eb577c
change-id: 20250731-add-more-socs-to-support-clk_measure-b2a43590d5aa

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

