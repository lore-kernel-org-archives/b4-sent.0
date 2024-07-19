From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 19 Jul 2024 16:08:09 +0800
Subject: [PATCH v3 1/6] dt-bindings: arm: amlogic: meson-gx-ao-secure:
 support more SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-soc_info-v3-1-020a3b687c0c@amlogic.com>
References: <20240719-soc_info-v3-0-020a3b687c0c@amlogic.com>
In-Reply-To: <20240719-soc_info-v3-0-020a3b687c0c@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721376490; l=1263;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=rEHcK7kDOz/ftRyqwGr3Rr5qy1WJIemzIVxERnlZdoA=;
 b=FfZmWKw4yC6wnxyxKyI818xy2bVTST+7yQ4+xM98MMp60iKFVe7ocInoteyPkz6tiqGZpJv8N
 4uIPQykCxl7AbrZ7NJX8VHJHVBnnv7dO2y6B+xaGkSpXODT6mu47faX
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new compatible for ao-secure of Amlogic SoCs(S4,C3,T7,A4).

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml | 16 ++++++++++++----
 1 file changed, 12 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml b/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml
index 7dff32f373cb..b4f6695a6015 100644
--- a/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml
@@ -25,10 +25,18 @@ select:
 
 properties:
   compatible:
-    items:
-      - const: amlogic,meson-gx-ao-secure
-      - const: syscon
-
+    oneOf:
+      - items:
+          - const: amlogic,meson-gx-ao-secure
+          - const: syscon
+      - items:
+          - enum:
+              - amlogic,a4-ao-secure
+              - amlogic,c3-ao-secure
+              - amlogic,s4-ao-secure
+              - amlogic,t7-ao-secure
+          - const: amlogic,meson-gx-ao-secure
+          - const: syscon
   reg:
     maxItems: 1
 

-- 
2.37.1

