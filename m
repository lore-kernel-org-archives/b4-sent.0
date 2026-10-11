From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Sun, 11 Oct 2026 19:51:28 +0300
Subject: [PATCH v5 6/7] dt-bindings: input: touchscreen: goodix: Add
 binding for GT970
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-msm8952-initial-support-v5-6-1857074992ec@mainlining.org>
References: <20261011-msm8952-initial-support-v5-0-1857074992ec@mainlining.org>
In-Reply-To: <20261011-msm8952-initial-support-v5-0-1857074992ec@mainlining.org>
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Bjorn Andersson <andersson@kernel.org>, 
 Abel Vesa <abelvesa@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: David Heidelberg <david@ixit.cz>, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-input@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791737529; l=1656;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=WcI6NF2jH7/1jsgO/qq/6GfopHH27DV/LBlXLYlg2yo=;
 b=Rd1+yUTn+zEQ8PrK7lbHPgXmB+k4Y09qQsr7ueDMR9GqQWjKcGeNJnMzBDj5zaF9wSZpPUlCP
 3XGa5o9eOtPA2OOvesO8/wWA+wxNKN7K2Y9aucmrE7DH1w42JQVuOIw
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GT970 works with GT911 driver, document it to be
used with GT911 compatible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 .../bindings/input/touchscreen/goodix.yaml         | 35 ++++++++++++----------
 1 file changed, 20 insertions(+), 15 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml b/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml
index a26a54d63a1c..4be2c137abd7 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml
@@ -14,21 +14,26 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - goodix,gt1151
-      - goodix,gt1158
-      - goodix,gt5663
-      - goodix,gt5688
-      - goodix,gt911
-      - goodix,gt9110
-      - goodix,gt912
-      - goodix,gt9147
-      - goodix,gt917s
-      - goodix,gt927
-      - goodix,gt9271
-      - goodix,gt928
-      - goodix,gt9286
-      - goodix,gt967
+    oneOf:
+      - enum:
+          - goodix,gt1151
+          - goodix,gt1158
+          - goodix,gt5663
+          - goodix,gt5688
+          - goodix,gt911
+          - goodix,gt9110
+          - goodix,gt912
+          - goodix,gt9147
+          - goodix,gt917s
+          - goodix,gt927
+          - goodix,gt9271
+          - goodix,gt928
+          - goodix,gt9286
+          - goodix,gt967
+      - items:
+          - enum:
+              - goodix,gt970
+          - const: goodix,gt911
 
   reg:
     enum: [ 0x5d, 0x14 ]

-- 
2.55.0

