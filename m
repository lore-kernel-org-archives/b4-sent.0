From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Fri, 20 Jun 2025 23:51:39 +0200
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: Add Flipkart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250620-rimob-initial-devicetree-v1-1-8e667ea21f82@protonmail.com>
References: <20250620-rimob-initial-devicetree-v1-0-8e667ea21f82@protonmail.com>
In-Reply-To: <20250620-rimob-initial-devicetree-v1-0-8e667ea21f82@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750456316; l=842;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=J+VRXXOlyvkdHa/6myly6nwuZ1NEFMyiM9bj1pJ3sO4=;
 b=qSGMlsCFJq9sLApq9yM4TwWq4CU49dBEZRH7UlJyRkXhbBEgy1iOEGwi4A7Ag2ZZiFmG1SrtY
 9VlSPJKMWL6Af6yzMW0JW75uy6qSE2fPMSPAytwyTgMMsy+rUjoBBaY
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

