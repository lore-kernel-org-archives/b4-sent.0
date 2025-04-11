From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH 0/7] soc: amlogic: clk-measure: Add clk-measure support for
 C3 and S4
Date: Fri, 11 Apr 2025 20:42:42 +0800
Message-Id: <20250411-clk-measure-v1-0-cb46a78d019a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEIO+WcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0ND3eScbN3c1MTi0qJU3RRj42TTxCQzIzMzSyWgjoKi1LTMCrBp0bG
 1tQD1zih3XQAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744375372; l=1025;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=4Ja56XexhMA1DCbBsQ1zoDOwfhujr3WsOePoWuHRSsc=;
 b=hNqHwd8xj6la7bifCJfhTbVRhSovhfmFzrYyzc9dzFgcKEAMHEqsdY6+AhrxaJauQy/eae5NF
 PLtq085pFpjCsXqAkyeugg02kDsfGTyViS4F7xDX3inqsLT5CYxyQfk
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add clk-measure support for C3/S4 SoCs.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
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
 drivers/soc/amlogic/meson-clk-measure.c            | 399 ++++++++++++++++++++-
 4 files changed, 396 insertions(+), 15 deletions(-)
---
base-commit: 37021be47d02d2913d6767795a6f4c72b4e63a4f
change-id: 20250411-clk-measure-d33c5ab62669

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

