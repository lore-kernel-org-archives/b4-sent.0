From: David Heidelberg <david@ixit.cz>
Date: Thu, 10 Apr 2025 16:28:19 +0200
Subject: [PATCH v5 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-synaptics-rmi4-v5-1-b41bb90f78b9@ixit.cz>
References: <20250410-synaptics-rmi4-v5-0-b41bb90f78b9@ixit.cz>
In-Reply-To: <20250410-synaptics-rmi4-v5-0-b41bb90f78b9@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Caleb Connolly <caleb.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1304; i=david@ixit.cz;
 h=from:subject:message-id; bh=vZ1A1BKo6qcJdGwTku+fpPYc8gaI2CIp5TJIm0fjjbo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn99WFPKRohmi+kM4ZwOrlgDzZ8E75/XLNBy1c0
 21mvrqCIdSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ/fVhQAKCRBgAj/E00kg
 cvghD/9ZcQbkw1tVd2KIYU39rQZH8BDZ5SUAf3Nb1lZwArrntOQANjeQHN1D7VOCPDz+mRK+IiP
 OBnObNOPr/NhYLvbxD4bbQUQvvRPF/shH9mPTIGrbaPZcloQLnH3onV1pqbGPSaRPIjB6BX2EzU
 hPVq7UjsMNR+x4HnSMmHc/j959chBjaUG7IRts2SkDb2XiFCWqART8nVs5+SMrzoeDt1sgn5HEQ
 3hdQQXMciIsxbonEH8HpT61pOdRDaYnaCuZ/fU3Y+3ceSQDJM7BbU3MYyyw8ZN6ibrRN75HllDZ
 phqOk2ti3O4UIbf3k1HOywxzMkTHa2qfFODdubI4ZMqytfLbP/eG25fXL2ZayMbQLy+hFHBppaI
 dDP2rvMWVHpmANOghMba9HENLriwDSwR1VQzUNOAQPCDwDqPC7f5R6K5Ojb0BQ3DGecZWM5+qIP
 IRSME8rr+pbH/qlL0FcxSzzjasMfA/JszSzArJ2YTBVeBzWgH8vDBYGd6KX3dMMzGdl/MQAbVdx
 G7WFjLI+6F3nq7e7YguI8+IOTTLFlrRR5k+bqYT+5e9Pt5YPvxIz/+nAcinAhr5NxZ+cGYEk2QH
 vvm5bKku7Dpn7wyuQVtxFu8o+fJ2zj7W8ebMhkOQse5AFMcWYmzVJ4rfDsRkeTffqeOwlENZIph
 uB60GktHxtOnjbQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly irrelevant for authentic Synaptics touchscreens, but very important
for applying workarounds to cheap TS knockoffs.

These knockoffs work well with the downstream driver, and since the user
has no way to distinguish them, later in this patch set, we introduce
workarounds to ensure they function as well as possible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index b522c8d3ce0db719ff379f2fefbdca79e73d027c..d5d0225e3826fa5a0559cbd99115c505ab113aa0 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -18,9 +18,14 @@ description: |
 
 properties:
   compatible:
-    enum:
-      - syna,rmi4-i2c
-      - syna,rmi4-spi
+    oneOf:
+      - enum:
+          - syna,rmi4-i2c
+          - syna,rmi4-spi
+      - items:
+          - enum:
+              - syna,rmi4-s3706b  # OnePlus 6/6T
+          - const: syna,rmi4-i2c
 
   reg:
     maxItems: 1

-- 
2.49.0

