From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Mar 2025 17:26:35 +0800
Subject: [PATCH 1/2] dt-bindings: pinctl: amlogic,pinctrl-a4: Add
 compatible string for A5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250327-a5-pinctrl-v1-1-49320349c463@amlogic.com>
References: <20250327-a5-pinctrl-v1-0-49320349c463@amlogic.com>
In-Reply-To: <20250327-a5-pinctrl-v1-0-49320349c463@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743067595; l=1027;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=e5E9HFKA/8VjQVYFNbNKCkIxF4wUBI+C617RgTKcAFA=;
 b=pfftSA0ow6ohkIHTU+RWjU9yarMrpHvElbzsyk2KJTNSA9+b8jmLlFm29TCzBbghYrNou4Tb2
 v9QUnNPCRC3DmidQRzDZVEGIb+eTMSyJmT+46B5tBYSl8VXShJGvkKa
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A5 SoCs uses the same pintrl controller as A4 SoCs. There is
no need for an extra compatible line in the driver, but add A5
compatible line for documentation.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml          | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
index 8eb50cad61d5..a94f4dfb9a7f 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,pinctrl-a4.yaml
@@ -14,8 +14,13 @@ allOf:
 
 properties:
   compatible:
-    const: amlogic,pinctrl-a4
-
+    oneOf:
+      - enum:
+          - amlogic,pinctrl-a4
+      - items:
+          - enum:
+              - amlogic,pinctrl-a5
+          - const: amlogic,pinctrl-a4
   "#address-cells":
     const: 2
 

-- 
2.37.1

