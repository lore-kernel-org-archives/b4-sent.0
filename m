From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 17 Jul 2025 17:38:37 +0800
Subject: [PATCH 1/2] dt-bindings: rtc: amlogic,a4-rtc: Add compatible
 string for C3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250717-rtc-c3-node-v1-1-4f9ae059b8e6@amlogic.com>
References: <20250717-rtc-c3-node-v1-0-4f9ae059b8e6@amlogic.com>
In-Reply-To: <20250717-rtc-c3-node-v1-0-4f9ae059b8e6@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752745121; l=1022;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=hzR0ZCHlhb6lBSnaSo2wyYzPsJkwt/jiH2b4zUOXQGs=;
 b=V19qxhXEYCFJdcPhLmr3zFhQT7TnOpLv6c6lf32Vyc9pC8x2fbEg0uajlnV9BYMTjc7yPC5kI
 DU6TCgBiRRNCenfVJMYxDrLudHQU9RYjt/AcrE38bnYfmN6uoVPzWxb
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic C3 SoCs uses the same rtc controller as A5 SoCs. There is
no need for an extra compatible line in the driver, but add C3
compatible line for documentation.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml b/Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml
index 5d3ac737abcb..e61f22eca85b 100644
--- a/Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml
+++ b/Documentation/devicetree/bindings/rtc/amlogic,a4-rtc.yaml
@@ -16,9 +16,14 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - amlogic,a4-rtc
-      - amlogic,a5-rtc
+    oneOf:
+      - enum:
+          - amlogic,a4-rtc
+          - amlogic,a5-rtc
+      - items:
+          - enum:
+              - amlogic,c3-rtc
+          - const: amlogic,a5-rtc
 
   reg:
     maxItems: 1

-- 
2.37.1

