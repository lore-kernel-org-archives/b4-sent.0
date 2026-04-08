From: David Heidelberg <david@ixit.cz>
Date: Thu, 09 Apr 2026 00:15:52 +0200
Subject: [PATCH v4 09/11] dt-bindings: input: touchscreen: st,stmfts:
 Introduce STM FTS5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260409-stmfts5-v4-9-64fe62027db5@ixit.cz>
References: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
In-Reply-To: <20260409-stmfts5-v4-0-64fe62027db5@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1tOSgCz7jjy058wzeL7LEkYevCLbVWdEmzY1J
 Rkf7VMNi46JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadbTkgAKCRBgAj/E00kg
 cpX5D/oCsqGXfeV1fdW/6kPezRfYNu5hhWyw2cIJv2dQySwVh3VIq/lGZPocjSySj/ZqaaOV+c+
 QJTF4ztbrpockeRkdSjn1jAiitpI6pRMmmZrgFooZXmWRW4nbnKeU/KduTJESeV+/87YHWAAhZW
 J/3BBXIoNOz8UJWO74AtUzniMZLLg3d6UEyuHq6SoWAHvk+mcD0L0To0/V2/CjY4Focrw0b7MdW
 kVezi/67hyObLSWoAb17K0Y5YHlKSac3hN8qZfdVxJrIelIDV7yVmI2zfBIvfyTOxFv3eQW2q6A
 ujJ0o3qvv/2w+Q6STHp/UEn2+bUHxn/rrCQt79Ey9NvIDTp+gwzYxBpglNAYo9NJjgd/ioxTSd6
 ukaEOGEq97o5BV8DbYRLH5ZH2PHpWm/dfKjEiFdjCzGV5XnhY58+6yx8YxyGebQpJMadkGByr5Q
 oZvXvM0JEQcdmW0rcNpyvZBiYARyDo3wuwevv1EF+1NBF3vgiWnrm/2BRYVSh3H4lzOiPOO2tdd
 ZKbIc3XhChBKg90OO2g35xjLR7p8+Yl9ykvdAvH30xxEWZmqx28jXrW33XHYEsoe2EE9H3u6XHq
 Vrcp+m10PE00u0oVk8dwKd+hIzWNRuhU79eKzTcapUzO5fUBIddcmrG1TU870LA6t7Kzxevfvdl
 A3sh9vK8HMeppZw==
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

