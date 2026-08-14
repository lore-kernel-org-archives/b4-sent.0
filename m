From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 14 Aug 2026 13:17:15 -0500
Subject: [PATCH 1/4] dt-bindings: display: visionox,vtdr6130: Add Retroid
 Pocket 6 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-rp6-panel-v1-1-111c1aeccf0f@gmail.com>
References: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
In-Reply-To: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786731444; l=1399;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=cQAQT+SLMV+AccWuQQKaYy2+/aNZWvo6kpA1OLjfeeY=;
 b=A+OJcGc0F92v2IjBPJqtFUxJPBwVQP3I5db3lJXiaBz0ehSB6z9WkgxJyWku6MwVq9Xs2tiUp
 Gu2NF5e4thSDn7/DDNVVnVojfvHStxAXVgJgh1TocmUg1RXOynWzqA2
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The vtdr6130 is a display driver integrated circuit, a common chip used
for various panels. One such panel is used in the Retroid Pocket 6.

The RP6 panel only lists the regulators vddio and vci, so drop vdd as a
required property. The panel is rotated 270 degrees to natural, so also
add rotation as an allowed property.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../devicetree/bindings/display/panel/visionox,vtdr6130.yaml      | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/visionox,vtdr6130.yaml b/Documentation/devicetree/bindings/display/panel/visionox,vtdr6130.yaml
index c99f4146f1bb0..682f30dc9ee43 100644
--- a/Documentation/devicetree/bindings/display/panel/visionox,vtdr6130.yaml
+++ b/Documentation/devicetree/bindings/display/panel/visionox,vtdr6130.yaml
@@ -14,7 +14,11 @@ allOf:
 
 properties:
   compatible:
-    const: visionox,vtdr6130
+    oneOf:
+      - const: visionox,vtdr6130
+      - items:
+          - const: retroidpocket,rp6-panel
+          - const: visionox,vtdr6130
 
   reg:
     maxItems: 1
@@ -25,13 +29,13 @@ properties:
   vdd-supply: true
   port: true
   reset-gpios: true
+  rotation: true
 
 required:
   - compatible
   - reg
   - vddio-supply
   - vci-supply
-  - vdd-supply
   - reset-gpios
   - port
 

-- 
2.54.0

