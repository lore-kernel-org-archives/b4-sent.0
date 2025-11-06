From: David Heidelberg <david@ixit.cz>
Date: Thu, 06 Nov 2025 11:36:59 +0100
Subject: [PATCH] dt-bindings: panel: s6e3fc2x01: Sort and remove
 unnecessary properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251106-dt-s6e3fc2x01-v1-1-0479f2d8b53f@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAEp6DGkC/x3MPQqAMAxA4atIZgNNxRa8ijj0J9UsKq1IQby7x
 fEb3nugcBYuMHUPZL6lyLE3UN9B2Ny+MkpsBq30SKQMxguL4SEFXRVhtM7GwbAnH6A1Z+Yk9f/
 Ny/t+ZW1ET18AAAA=
X-Change-ID: 20251106-dt-s6e3fc2x01-d7a7d36eb1bc
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1829; i=david@ixit.cz;
 h=from:subject:message-id; bh=1KDAH+YpEy+rZDz3Q9O9UwxUiZX+yY2cR18RR7GgY04=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpDHpVj6JEO0HK+rGxbwLrFh6Q5T+5Su7vWvL6Q
 YB4nrdnyaCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQx6VQAKCRBgAj/E00kg
 ctirD/sFPN0KSNSsj6NjI0HjAusuMkskUFWozdEH0DEJzGpPp5FXfvb1yiwv4TMxUXvIM7flRvF
 z7y/NUWcL16HBT/UJlHMWMkcd+55OQd1VCysHfS7b1q1+KxQeO7y2EghSP84zxpP8/NR6rDJ4bg
 lETYEbTkMNwNcqh1hWlUZ2gLgRmkQwf3TeoCoInrAL8AHgsU3Vtc4Ny6879DHE9+e4L5rLrE5EQ
 lDp33CeG1S2/DzTBjhiBV8K4Oa+HL+CiQtDh6pWMTvn4LY1FRFLxUfpPTy+kbdKnK/xN7OYHXhn
 t/4TPSH49yqSzyCHKLwnwi9RxC8jmgyVxBY5x6IloN3AJ29BTHY+kcaU03fK+0LC4rOL6HGguEW
 muOErDYBn4LuLO6xVGqDZsSk3AsnLPTP7/ApvIkP/fBM+XUFLKmqqe4BllNPDjVCR7IYNRDyEfC
 ai1Es6Oe50TOcI2vFEK6pabYAgKLC8JdaBUpHDNqX8uChHhqbmR8yyBsfgX0cZu7ph/kwJBqOSJ
 Ogi3oRWErubwyxPvRvdLrZ3g/DJtCFdm+wfNW2lJysXMBRXyzm73HWI1yYe6SXv+ym6XU0o2zOr
 SMFwtCsolWmapxkyeWAPn6hU0yeXrokWCNO504tYPXww9oRt1iCPH3LENGCIUnS/VFPm4fcmEOd
 pfwfTRMsIP8v5Tw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Properties are now sorted, reset-gpio and port property dropped.

Fixes: 986f28f3a71e ("dt-bindings: panel: Add Samsung S6E3FC2X01 DDIC with panel")
Suggested-by: Krzysztof Kozlowski <krzk@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/display/panel/samsung,s6e3fc2x01.yaml   | 20 ++++++++------------
 1 file changed, 8 insertions(+), 12 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml b/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
index d48354fb52ea0..fd4388f5fb118 100644
--- a/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
+++ b/Documentation/devicetree/bindings/display/panel/samsung,s6e3fc2x01.yaml
@@ -6,11 +6,11 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title: Samsung S6E3FC2X01 AMOLED DDIC
 
-description: The S6E3FC2X01 is display driver IC with connected panel.
-
 maintainers:
   - David Heidelberg <david@ixit.cz>
 
+description: The S6E3FC2X01 is display driver IC with connected panel.
+
 allOf:
   - $ref: panel-common.yaml#
 
@@ -25,25 +25,21 @@ properties:
   reg:
     maxItems: 1
 
-  reset-gpios: true
-
-  port: true
-
-  vddio-supply:
-    description: VDD regulator
+  poc-supply:
+    description: POC regulator
 
   vci-supply:
     description: VCI regulator
 
-  poc-supply:
-    description: POC regulator
+  vddio-supply:
+    description: VDD regulator
 
 required:
   - compatible
   - reset-gpios
-  - vddio-supply
-  - vci-supply
   - poc-supply
+  - vci-supply
+  - vddio-supply
 
 unevaluatedProperties: false
 

---
base-commit: df5d79720b152e7ff058f11ed7e88d5b5c8d2a0c
change-id: 20251106-dt-s6e3fc2x01-d7a7d36eb1bc

Best regards,
-- 
David Heidelberg <david@ixit.cz>

