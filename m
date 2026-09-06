From: =?utf-8?q?Juan_Carlos_Guti=C3=A9rrez_Lavado?= <jcarlosgl96@proton.me>
Date: Sun, 06 Sep 2026 16:05:49 +0000
Subject: [PATCH 1/2] dt-bindings: arm: sunxi: Add SPC Glee 10.1 A64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260906-b4-spc-glee-a64-v1-v1-1-621df2155e31@proton.me>
References: <20260906-b4-spc-glee-a64-v1-v1-0-621df2155e31@proton.me>
In-Reply-To: <20260906-b4-spc-glee-a64-v1-v1-0-621df2155e31@proton.me>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Juan_Carlos_Guti=C3=A9rrez_Lavado?= <jcarlosgl96@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788710758; l=1596;
 i=jcarlosgl96@proton.me; s=20260906; h=from:subject:message-id;
 bh=2sTHkEIZ9R2X36In5QhZ4ozs/BXQZzuqStbGUoIn0/8=;
 b=PawChL5wDUDLG0nHuI8bLkcI2Gg3HO3qY1ESyyPWDgu6r45I1S1MpUoJUa6l9YXdauMIgVMc7
 X1s/4Mi5jOoAwlVfDq1T1ChCyDXymDo/1kiBnR7NAZ86NrBE3zXxddB
X-Developer-Key: i=jcarlosgl96@proton.me; a=ed25519;
 pk=2/GzZfrbHAiuUrsA5A4A9ixfHKnypfDfzyE+fToY4Io=
X-Endpoint-Received: by B4 Relay for jcarlosgl96@proton.me/20260906 with auth_id=1008
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Smart Products Connection vendor prefix and the board
compatible for the SPC Glee 10.1 tablet based on the Allwinner A64.

Signed-off-by: Juan Carlos Gutiérrez Lavado <jcarlosgl96@proton.me>
---
 Documentation/devicetree/bindings/arm/sunxi.yaml       | 5 +++++
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 2 files changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/sunxi.yaml b/Documentation/devicetree/bindings/arm/sunxi.yaml
index f04db28c6..ce425938c 100644
--- a/Documentation/devicetree/bindings/arm/sunxi.yaml
+++ b/Documentation/devicetree/bindings/arm/sunxi.yaml
@@ -902,6 +902,11 @@ properties:
           - const: allwinner,suniv-f1c200s
           - const: allwinner,suniv-f1c100s
 
+      - description: SPC Glee 10.1 A64 tablet
+        items:
+          - const: spc,glee-10-1-a64
+          - const: allwinner,sun50i-a64
+
       - description: SL631 Action Camera with IMX179
         items:
           - const: allwinner,sl631-imx179
diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index ba2002969..ff462d6f0 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1603,6 +1603,8 @@ patternProperties:
     description: Spansion Inc.
   "^sparkfun,.*":
     description: SparkFun Electronics
+  "^spc,.*":
+    description: Smart Products Connection S.A.
   "^spinalhdl,.*":
     description: SpinalHDL
   "^sprd,.*":

-- 
2.55.0

