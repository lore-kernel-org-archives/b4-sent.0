From: Long Zhao <longzhao@ambarella.com>
Date: Wed, 14 Oct 2026 01:46:00 +0800
Subject: [PATCH] dt-bindings: vendor-prefixes: add Ambarella
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-cv75-prefix-v1-1-fe95ed567880@ambarella.com>
X-B4-Tracking: v=1; b=H4sIAFduzmoC/yWNzQ5AMBCEX0X2rEnb+H8VcaAW64B0ESJ9dy3Hb
 zLzzQOMlpChih6weBLTunhQcQRmapcRBfWeQUudKakSYc48FZvFgS6RYNEpI9u81yX4xR9/trr
 5mY9uRrMHRWhMxPtq73DnnHsB9JFY7H4AAAA=
X-Change-ID: 20261014-cv75-prefix-4e8b1c0a7d29
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Linus Walleij <linusw@kernel.org>, devicetree@vger.kernel.org, 
 Long Zhao <zl020895@163.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791913588; l=1442;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=/DBR6bJT9D7LQ4feEnzdAHUOtPgBVZpuVoWKIq8de8w=;
 b=HBTRhm1gjTs0qja+wL9IWY5zHWPD46YwsAvZnu/RgayZpaETzqhNCbT/WnJiPVMaJ1ei6l9jB
 fg7IHg6aixqDT7SzNh1RugYBMhIAO1DzAsf8+WUFzXRG3bz2EQtMb2J
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Ambarella, Inc. vendor prefix so Ambarella DT bindings
can be applied without waiting for the SoC series.

Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: Linus Walleij <linusw@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 85a27937832e..f48aa6dabbe9 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -112,6 +112,8 @@ patternProperties:
     description: Amarula Solutions
   "^amazon,.*":
     description: Amazon.com, Inc.
+  "^ambarella,.*":
+    description: Ambarella, Inc.
   "^amcc,.*":
     description: Applied Micro Circuits Corporation (APM, formally AMCC)
   "^amd,.*":

---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261014-cv75-prefix-4e8b1c0a7d29

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

