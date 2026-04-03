From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 19:08:38 +0200
Subject: [PATCH WIP v3 09/11] dt-bindings: input: touchscreen: st,stmfts:
 Introduce STM FTS5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-stmfts5-v3-9-5da768cfd201@ixit.cz>
References: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
In-Reply-To: <20260403-stmfts5-v3-0-5da768cfd201@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1224; i=david@ixit.cz;
 h=from:subject:message-id; bh=ghceD3FEXE+XcrRARnEBBTznzq4UXU11eu6mo0R07f4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/QQhvsLT2ghVPtEcPOErYK1bc52pLTCthXwp
 ayNpsJ4oM2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/0EAAKCRBgAj/E00kg
 cmWjD/41YbgUbGKSLEOxiv4PEGfIIQ4wktekQFoSv6iBkVkiPTHmNUqUjbL3wgSp1QZ7Z4ipdSY
 mrPrBwC4BKYZVtdpkhHIhYBLxTmTl70bVUKx9WUhKM+Fx9nDbtkRS0JErFzje16MgXsoWS7CYE3
 twq13rtFuLVjiTnTvq1wXh48nUjMq0ye3TMTGNhdJPXAYT5XlAWq3GaX1GRaEmqB1kgwRiquDhM
 BentjBlfrkUrLLi3gGy+dz4kZO5YlOQ3rE5kza9WQh8CMdiFv6bfjxvwHN1ox6760pWlY1yOPN7
 fHUIxflF5Szx6O+Lo2SrZx2oAgvn8CDIZSFNJRJhTTHuAvxpj48Vu7StI9g08XgGbQxRVhogeZK
 z5DO1v3hKn0EPl+Z0AHM8hTj/oDIvRKbNCFPp2wQvbUhIDmxAAGN48sj2ij6fdv/mPB9G7mWD3M
 lVODfOzLol/wxgiJ+s4KzHLIAOI4cQErRtA59LYQUBChNKuEIzmFguF0y7WAm/o+PfxWoMvQKVc
 416VuonE3Ex/+kqeBRoRW5ryV+5jpa14SwcbQLAsoIAG936TePuvV+A+yUCnZXHwOQP/N98wCtL
 9PRFpdi/vhSg2tVMftRkFJ7At5cisCuwspm1zc+XwjpEA3XLjrOOSsKQox9Qk0mhqGgcEdEMpp9
 vhKhmH8u+AqfWtw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce more recent STM FTS5 touchscreen support.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/input/touchscreen/st,stmfts.yaml  | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
index 64c4f24ea3dd0..441fc92b9a4ed 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
@@ -16,10 +16,19 @@ description:
 
 allOf:
   - $ref: touchscreen.yaml#
+  - if:
+      properties:
+        compatible:
+          const: st,stmfts5
+    then:
+      required:
+        - mode-switch-gpios
 
 properties:
   compatible:
-    const: st,stmfts
+    enum:
+      - st,stmfts
+      - st,stmfts5
 
   reg:
     maxItems: 1
@@ -40,6 +49,10 @@ properties:
   vdd-supply:
     description: Power supply
 
+  mode-switch-gpios:
+    description: Switch between touchscreen SLPI and AP mode.
+    maxItems: 1
+
   reset-gpios:
     description: Reset GPIO (active-low)
     maxItems: 1

-- 
2.53.0

