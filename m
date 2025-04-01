From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 01 Apr 2025 10:06:21 +0800
Subject: [PATCH v2 1/2] dt-bindings: pinctl: amlogic,pinctrl-a4: Add
 compatible string for A5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250401-a5-pinctrl-v2-1-a136c1058379@amlogic.com>
References: <20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com>
In-Reply-To: <20250401-a5-pinctrl-v2-0-a136c1058379@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743473181; l=1067;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Pz16Z/QIM4IDWi5UYrztmMtclbTkct1CDyubtK9KYn4=;
 b=tIqYXqlrL3cEMBuUkhDpDT5x01qWCw09VqlUKfVE39cA28tUMi3sre+NqfzZ/BF1MsNdR5Y+x
 JnrhDuK6GLjDEIESc2nkxjj654ABNisplxGeYWxPACxP6Q7yX2w4EQd
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A5 SoCs uses the same pintrl controller as A4 SoCs. There is
no need for an extra compatible line in the driver, but add A5
compatible line for documentation.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
index 8eb50cad61d5..3bebccaf0c9f 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -14,8 +14,12 @@ allOf:
 
 properties:
   compatible:
-    const: amlogic,pinctrl-a4
-
+    oneOf:
+      - const: amlogic,pinctrl-a4
+      - items:
+          - enum:
+              - amlogic,pinctrl-a5
+          - const: amlogic,pinctrl-a4
   "#address-cells":
     const: 2
 

-- 
2.37.1

