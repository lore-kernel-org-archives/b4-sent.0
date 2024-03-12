From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 12 Mar 2024 17:18:58 +0800
Subject: [PATCH 2/4] dt-bindings: arm: amlogic: add A5 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240312-basic_dt-v1-2-7f11df3a0896@amlogic.com>
References: <20240312-basic_dt-v1-0-7f11df3a0896@amlogic.com>
In-Reply-To: <20240312-basic_dt-v1-0-7f11df3a0896@amlogic.com>
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710235139; l=998;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=OjYemETinzmeJ9Q4YrGV5qbHibSqK0gJRNB1l5DOrLo=;
 b=tFHNPr2tadjZI0f7yRXUHfGbas/LCBRkjU+cD60xc4dwRmucwJfD80aGFsMz+cb+Z2SBUuaOU
 74GeQ1M93BzDp4bVIzFNNlPxL0TvuH7avkGhY8wfhLiRFYGh5XVTY0l
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the new A5 SoC/board device tree bindings.

Amlogic A5 is an application processor designed for smart audio
and IoT applications.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/arm/amlogic.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/amlogic.yaml b/Documentation/devicetree/bindings/arm/amlogic.yaml
index 9a135fe1c862..6090cb674b65 100644
--- a/Documentation/devicetree/bindings/arm/amlogic.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic.yaml
@@ -209,6 +209,13 @@ properties:
               - amlogic,ba409
           - const: amlogic,a4
 
+      - description: Boards with the Amlogic A5 A113X2 SoC
+        items:
+          - enum:
+              - amlogic,av400
+              - amlogic,av409
+          - const: amlogic,a5
+
       - description: Boards with the Amlogic C3 C302X/C308L SoC
         items:
           - enum:

-- 
2.37.1

