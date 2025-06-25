From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Thu, 26 Jun 2025 00:04:26 +0200
Subject: [PATCH v3 1/3] dt-bindings: vendor-prefixes: Add Flipkart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250626-rimob-initial-devicetree-v3-1-4017ac9fd93d@protonmail.com>
References: <20250626-rimob-initial-devicetree-v3-0-4017ac9fd93d@protonmail.com>
In-Reply-To: <20250626-rimob-initial-devicetree-v3-0-4017ac9fd93d@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750889075; l=842;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=J+VRXXOlyvkdHa/6myly6nwuZ1NEFMyiM9bj1pJ3sO4=;
 b=in5Ga6yKXLSHm6A0EsHFeUzK+jJ3dZEuUPa8Fh2QNSW/pZUG4xBvtn2RzrSqQdAsnq+7OZ6Jp
 A1rrMlYkcLuC/QVhlJtrmYN+lmcRnJSUkXMdO6o+L00YkBCeXbYvFw1
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Flipkart to the vendor prefixes.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 86f6a19b28ae217643bf7a63a471f74819d18238..1516d670e3ac81e3e00fb687cda64d50eb3e2049 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -535,6 +535,8 @@ patternProperties:
     description: Foxconn Industrial Internet
   "^firefly,.*":
     description: Firefly
+  "^flipkart,.*":
+    description: Flipkart Inc.
   "^focaltech,.*":
     description: FocalTech Systems Co.,Ltd
   "^forlinx,.*":

-- 
2.49.0

