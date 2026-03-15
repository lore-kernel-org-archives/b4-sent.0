From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 19:52:45 +0100
Subject: [PATCH WIP v2 09/11] dt-bindings: input: touchscreen: st,stmfts:
 Introduce STM FTS5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-stmfts5-v2-9-70bc83ee9591@ixit.cz>
References: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
In-Reply-To: <20260315-stmfts5-v2-0-70bc83ee9591@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1055; i=david@ixit.cz;
 h=from:subject:message-id; bh=h9cECjq5ixf532xdPZjxPL80kJ11WrP4Xf5V/9RKA7Q=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptv/6lnDIMavIrwcYtj0lh0pCOWzu3RevBl4UZ
 /fzW91xkmuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabb/+gAKCRBgAj/E00kg
 cvsJD/0Qp9xOpywUTHGKd9kmlHiS+une24wyAVlUwl4wIPH99T9Kz0GpdLiNi5iLoXZ+IVDMn55
 3EgVHXRuT0jTAb9x1gavYNq7Y6xjMhL1Nwy/kW4ihm8F6n60RjJUWlHCUK5hjtUgk3zdIcoO2Zi
 2uA09vJvOAyTyKLYUO6TwSab9cwEm3R5VqtJ1JMGCFMtUKGYY6QoThCx+B1Y0DnDE65L8WrsG+R
 nhmbFZFT/J6hOz/e4K4hkwA2ZjCp2t/2UrwTBwEXH09LT/KUV/uoWdRoC4dxgFZVsi57+i+ogRf
 Wknku5jEaEjXRJxk0EwP5rHkfmcdE0wbIQV1LUnlafnGEAEt2JW9aacE1mT7qBfdjCECl8xYPxZ
 V4nBwCsNrJEiOj8ouYuWEFcnJ3pZU10+SUWn7I5eudR18D8RUgC0QhzR5p/ufmOBtz5jLja3xbL
 ie1Hkv59fizlA3mST2/S2O3THCSS9NiIXznmHNeYhoIyHaz9Pz4Ufo0Bio3OM0tWs7d5rMIwUrr
 YvbspcwL2xe4Cun+3BAXEy/CnVbKDt4aawnEsp7AN6BItGL7e99k7t0tX9KoJVMsynqt2tResa7
 NP3lxa1bLZ2sRhDT0S/ipLJEnWvWf8pfTug4OXPzyNR5XELfhfgXemKqHiy/vjM0hxflN6DFsCw
 NiiShg53lFQ9MXQ==
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
index 64c4f24ea3dd0..66255893a99fb 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
@@ -16,10 +16,23 @@ description:
 
 allOf:
   - $ref: touchscreen.yaml#
+  - if:
+      properties:
+        compatible:
+          const: st,stmfts5
+    then:
+      properties:
+        switch-gpios:
+          description: Switch between SLPI and AP mode.
+
+      required:
+        - switch-gpios
 
 properties:
   compatible:
-    const: st,stmfts
+    enum:
+      - st,stmfts
+      - st,stmfts5
 
   reg:
     maxItems: 1

-- 
2.53.0

