From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 06 Aug 2024 18:27:14 +0800
Subject: [PATCH 1/3] dt-bindings: clock: fix C3 PLL input parameter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240806-c3_add_node-v1-1-c0de41341632@amlogic.com>
References: <20240806-c3_add_node-v1-0-c0de41341632@amlogic.com>
In-Reply-To: <20240806-c3_add_node-v1-0-c0de41341632@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chuan Liu <chuan.liu@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722940034; l=1392;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=nOBPKUlDvxHHPW4LjnDlQ83HxUGqGNULEJwk23wSGII=;
 b=wJEXJtfDkx4Zaq3zaoUj1mqfl8KL/DhH/a/4rT0nQrjuMtW2rVxyxv9aaJ0z/7nyYP+dHL3a9
 vPYcwvGuVOkCHu4YcDg6BH4lOKe5kESpLj5mf/4Ctv+ytQFa5LnNnER
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add C3 PLL controller input clock parameters "fix".

Fixes: 0e6be855a96d ("dt-bindings: clock: add Amlogic C3 PLL clock controller")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/clock/amlogic,c3-pll-clkc.yaml | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,c3-pll-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,c3-pll-clkc.yaml
index 43de3c6fc1cf..700865cc9792 100644
--- a/Documentation/devicetree/bindings/clock/amlogic,c3-pll-clkc.yaml
+++ b/Documentation/devicetree/bindings/clock/amlogic,c3-pll-clkc.yaml
@@ -24,11 +24,13 @@ properties:
     items:
       - description: input top pll
       - description: input mclk pll
+      - description: input fix pll
 
   clock-names:
     items:
       - const: top
       - const: mclk
+      - const: fix
 
   "#clock-cells":
     const: 1
@@ -52,8 +54,9 @@ examples:
             compatible = "amlogic,c3-pll-clkc";
             reg = <0x0 0x8000 0x0 0x1a4>;
             clocks = <&scmi_clk 2>,
-                     <&scmi_clk 5>;
-            clock-names = "top", "mclk";
+                     <&scmi_clk 5>,
+                     <&scmi_clk 12>;
+            clock-names = "top", "mclk", "fix";
             #clock-cells = <1>;
         };
     };

-- 
2.37.1

