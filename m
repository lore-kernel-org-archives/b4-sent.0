From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v2 0/7] soc: amlogic: clk-measure: Add clk-measure support
 for C3 and S4
Date: Mon, 14 Apr 2025 18:12:27 +0800
Message-Id: <20250414-clk-measure-v2-0-65077690053a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIvf/GcC/23MQQ7CIBCF4as0sxYDtEXblfcwXVAY24mlGFCia
 bi72LXL/yXv2yBiIIzQVxsETBTJryXkoQIz63VCRrY0SC5b3gjBzHJnDnV8BWS2rk2rRyWV6qA
 8HgFv9N6161B6pvj04bPjSfzW/04SjDMzNkqfzpaLTl+0W/xE5mi8gyHn/AVxRZfkqAAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744625573; l=1253;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=8/5+Mwb/Pk1qbvhX1PLg4XvpKaWqdiHo6PVGtnDXOBg=;
 b=ZH0NEy35W5gs/Tu2051Lyxrw35300elFLKMkQjYgn1ytG5I5ExkRe0Ac/OHwoZohJ3lnXRu65
 XNKR6HG9AfuASs6Z2IWOLeUazeEMbq6wNKIRYHw59Rdgr+/tk2OucSD
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add clk-measure support for C3/S4 SoCs.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Changes in v2:
- 1 Rename the clk-measure register.
- 2 Remove unused registers.
- 3 Share reg_offset across multiple chips.
- Link to v1: https://lore.kernel.org/r/20250411-clk-measure-v1-0-cb46a78d019a@amlogic.com

---
Chuan Liu (7):
      soc: amlogic: clk-measure: Define MSR_CLK's register offset separately
      dt-bindings: soc: amlogic: C3 supports clk-measure
      dt-bindings: soc: amlogic: S4 supports clk-measure
      soc: amlogic: clk-measure: Add support for C3
      soc: amlogic: clk-measure: Add support for S4
      arm64: dts: amlogic: C3: Add clk-measure controller node
      arm64: dts: amlogic: S4: Add clk-measure controller node

 .../soc/amlogic/amlogic,meson-gx-clk-measure.yaml  |   2 +
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        |   5 +
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          |   5 +
 drivers/soc/amlogic/meson-clk-measure.c            | 374 ++++++++++++++++++++-
 4 files changed, 371 insertions(+), 15 deletions(-)
---
base-commit: 37021be47d02d2913d6767795a6f4c72b4e63a4f
change-id: 20250411-clk-measure-d33c5ab62669

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

