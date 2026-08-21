From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 20 Aug 2026 22:30:46 -0500
Subject: [PATCH v2 1/4] dt-bindings: vendor-prefixes: Add Retroid Pocket
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-rp-qcs8550-v2-1-d4ce78fe9385@gmail.com>
References: <20260820-rp-qcs8550-v2-0-d4ce78fe9385@gmail.com>
In-Reply-To: <20260820-rp-qcs8550-v2-0-d4ce78fe9385@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787283066; l=915;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=pgxhUlLLIL0s7PQ+Oz8ayGXR7ERpF2skLnamCW8kj9g=;
 b=r/S4fNWlha1+SegojvuMspUR9N7Fc90mkHTBBG8GQ74tE5uHRC6yeZI/Iy8s3vmddwgHsLLFn
 PNpKpLBGJAFB32gLpF9LQvsFDlLAU9BlRjOtfvhN/BtY5klUqHAdZWE
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for Retroid Pocket (https://www.goretroid.com/)

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 8e6307897d051..2c2502feff612 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1421,6 +1421,8 @@ patternProperties:
     description: Renesas Electronics Corporation
   "^rervision,.*":
     description: Shenzhen Rervision Technology Co., Ltd.
+  "^retroidpocket,.*":
+    description: Retroid Pocket
   "^retronix,.*":
     description: Retronix Technology Inc.
   "^revotics,.*":

-- 
2.54.0

