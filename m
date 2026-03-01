From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 18:51:22 +0100
Subject: [PATCH 08/10] dt-bindings: input: touchscreen: st,stmfts:
 Introduce STM FTS5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-stmfts5-v1-8-22c458b9ac68@ixit.cz>
References: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
In-Reply-To: <20260301-stmfts5-v1-0-22c458b9ac68@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1158; i=david@ixit.cz;
 h=from:subject:message-id; bh=hq9RJ0MPDH3qjbBs4V4v4YyIoe73PSNk1u1yb638HiY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppHyVCoxRU7IViUqu//ep20pNs3plY0LsjQwgQ
 lDE67NHdlWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaR8lQAKCRBgAj/E00kg
 co93D/9PCMgQHcgoRm260zPygFP00u9m2DCOEZSMzuD4dRL4nBeebVnK7tWlZOCUgc1Tk0pyxf0
 QvYfnMkKFpTQwqj+S+Tje/BEeqI2XP77/OW8qTx4pVab7h88y1lo1z1G/T1nGqfnedrn3iQFpG3
 7Unluofdg94QhqjPVx18olmR6T3OuY467B6j2fK5UjZMkv84ndIJF5AUFRiZgNPffoWAWO8v77F
 foYfGO4Biy1VtPIkyozYea9ZDTsO5z2j8Y3x52Eet3bUITLySIvC15ocbPaxT6qroGf9JICPAz6
 NxlnqhAKnBNK9V4sGzHQ/o8aRPoIs2P8svd4WjJyA3eu+CEy1ILbJQ5RTc9Qu2HULTDdtr8wMKo
 3OmhYBpX0bqHjb2HRN3wX7bFVwENH46wM+hAPmhzQUcY0nAywkME7d9GvdcH7SYt/Dd0G5vUz5c
 6XtPfKED2ok1y4wvFZJ9BdnxrK48bXVqUBAp9L4CpwjKtaDu4uRRBtyVZXNUjATH1+W/qmrkjYT
 8K35YL7wyplFX369igIdXYxrGAiEGJhOhE2BQgYikAw/xj1G9D2yixFq+NhH++Ypke1yixmXVVf
 dcvXvW8T3dq8/TUlD8FqLdqHLxOgceK/qlcIqz68odYJdJCKkTjSgpoTp+AbVMDmrHnQZfqQKFA
 hgcL0puDUAOlU4w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce more recent STM FTS5 touchscreen support.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/input/touchscreen/st,stmfts.yaml           | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
index 64c4f24ea3dd0..329d89977bdbc 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
@@ -19,7 +19,9 @@ allOf:
 
 properties:
   compatible:
-    const: st,stmfts
+    enum:
+      - st,stmfts
+      - st,stmfts5
 
   reg:
     maxItems: 1
@@ -53,6 +55,19 @@ required:
 
 unevaluatedProperties: false
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          const: st,stmfts5
+    then:
+      properties:
+        switch-gpio:
+          description: Switch between SLPI and AP mode.
+
+      required:
+        - switch-gpio
+
 examples:
   - |
     #include <dt-bindings/interrupt-controller/irq.h>

-- 
2.51.0

