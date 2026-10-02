From: Igor Velkov <iav@iav.lv>
Subject: [PATCH v2 0/2] arm64: dts: amlogic: meson-sm1-odroid-hc4: fix the
 SPI NOR
Date: Fri, 02 Oct 2026 21:36:45 +0300
Message-Id: <20261002-hc4-spi-nor-v2-0-8366a4f91049@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL35v2oC/23MQQrCMBCF4auUWTsySVppXHkP6SLU0QxIUhIJl
 pK7N3bt8n/wvg0yJ+EM126DxEWyxNBCnzqYvQsvRnm0Bk36QtYQ+rnHvAiGmNCNpAbNhtgpaI8
 l8VO+h3afWnvJn5jWAy/qt/53ikJC64wZFGs79nwTV87vAlOtdQfMm6CfowAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Christian Hewitt <christianshewitt@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1092; i=iav@iav.lv;
 h=from:subject:message-id; bh=b1yPZi82g5YJjfiKmfE3necw60fkrcFAPcinKeqKRUs=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn7f+4N1HnAzNsq2ufuFNnO8HmGxIMWXVHutOxnZT6yQ
 ietzuZ1lLIwiHExyIopskw4pHErY8nVv/4e5g9g5rAygQxh4OIUgIncTmf4X2Ha9crFovxM0lWX
 lX9qDv35fcD/REMti3+LrbDwn/MWtYwMK/u33irZ21L6sMJk1oQtlQUym7cFMt9vtp1qUCN361k
 wBwA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for the SPI NOR flash on ODROID-HC4. Patch 1 lets the flash
probe after a boot from SD that bypasses the SPI flash. Patch 2 lowers
the clock to 40 MHz, where reads stop returning corrupted data.

U-Boot takes this device tree from dts/upstream and gets the fixes with
the next sync.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- Patch 1: move the HOLD#/WP# group to meson-g12-common.dtsi (Neil).
  The HC4 dtb decompiles identically to v1.
- Link to v1: https://lore.kernel.org/r/20260930-hc4-spi-nor-v1-0-9a3351e2984e@iav.lv

---
Igor Velkov (2):
      arm64: dts: amlogic: meson-sm1-odroid-hc4: mux the SPI NOR HOLD# and WP# pins
      arm64: dts: amlogic: meson-sm1-odroid-hc4: run the SPI NOR at 40 MHz

 arch/arm64/boot/dts/amlogic/meson-g12-common.dtsi    | 9 +++++++++
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 4 ++--
 2 files changed, 11 insertions(+), 2 deletions(-)
---
base-commit: 065957517880dc7053e0723cc9532b6e78c8855c
change-id: 20260930-hc4-spi-nor-a80152e30ea1

Best regards,
-- 
Igor Velkov <iav@iav.lv>

