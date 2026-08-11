From: Robin Snyders <robin@snyders.xyz>
Date: Wed, 12 Aug 2026 01:56:59 +0200
Subject: [PATCH v2 1/2] dt-bindings: power: supply: qcom,pmi8998-charger:
 add SMB5 PMICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-submit-qcom-smbx-send-v1-v2-1-f504b8f9bfad@snyders.xyz>
References: <20260812-submit-qcom-smbx-send-v1-v2-0-f504b8f9bfad@snyders.xyz>
In-Reply-To: <20260812-submit-qcom-smbx-send-v1-v2-0-f504b8f9bfad@snyders.xyz>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786492653; l=2055;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=dbA6J4pyEhKqtE5cFdJw1mjwn3vo7LHk/ON/7cmUiY8=;
 b=oNDrBKKRzA3d+ClM5J/nzWYKUJTNbIl8E6KKzYABNjOa2iuKV7MLeGImkYiXxKCAO9iLt+uK4
 sVnoA0aEXx8AKQSMkd6YxxpFuVIxs8f+gObC4anf5Bb82LLnkM+v/Ol
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Add compatible strings for PM7250B and PM8150B, which contain the SMB5
generation of the Qualcomm switch-mode battery charger. PM7250B uses the
same charger interface and parameters as PM8150B, so require the PM8150B
compatible as its fallback.

Clarify the IIO channel descriptions because SMB5 exposes a USB current-
sense voltage while SMB2 exposes an already-converted current.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 .../bindings/power/supply/qcom,pmi8998-charger.yaml     | 17 +++++++++++------
 1 file changed, 11 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
index 70f5cd6eaeabe..25511e2e33691 100644
--- a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
@@ -4,16 +4,21 @@
 $id: http://devicetree.org/schemas/power/supply/qcom,pmi8998-charger.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Qualcomm PMI8998/PM660 Switch-Mode Battery Charger "2"
+title: Qualcomm SMB2 and SMB5 Switch-Mode Battery Charger
 
 maintainers:
   - Casey Connolly <casey.connolly@linaro.org>
 
 properties:
   compatible:
-    enum:
-      - qcom,pmi8998-charger
-      - qcom,pm660-charger
+    oneOf:
+      - enum:
+          - qcom,pmi8998-charger
+          - qcom,pm660-charger
+          - qcom,pm8150b-charger
+      - items:
+          - const: qcom,pm7250b-charger
+          - const: qcom,pm8150b-charger
 
   reg:
     maxItems: 1
@@ -30,8 +35,8 @@ properties:
 
   io-channels:
     items:
-      - description: USB in current in uA
-      - description: USB in voltage in uV
+      - description: USB input current or current-sense voltage measurement
+      - description: USB input voltage measurement
 
   io-channel-names:
     items:

-- 
2.54.0

