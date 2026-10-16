From: Ishu Brar <patches@brar.si>
Date: Fri, 16 Oct 2026 13:50:18 +0530
Subject: [PATCH 1/2] dt-bindings: remoteproc: qcom,sm6350-pas: Document
 SM7250 ADSP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-adsp-sm7250-v1-1-2f39ac1f0496@brar.si>
References: <20261016-adsp-sm7250-v1-0-2f39ac1f0496@brar.si>
In-Reply-To: <20261016-adsp-sm7250-v1-0-2f39ac1f0496@brar.si>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138822; l=1256;
 i=patches@brar.si; h=from:subject:message-id;
 bh=z1Qa0DEUjqiJUo+KWFEZ0IxthpbJqvNpcU9mepDGsGI=;
 b=0ps9BSiImVNiWX1nXu7otNLfAfp3zFp1BKVoU9SXFUn+x1U/AYS5T5W5ytbPmdXlpYZFmllJC
 7dUui3uSHfTCvFQ1JFkZrSZS+C2VRRGW+ET2NwMVPZSl0uiY7iUMpER
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the ADSP Peripheral Authentication Service on the Qualcomm
SM7250 SoC. It has the same interrupts and LCX/LMX power domains as the
SM6350 ADSP.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml b/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml
index 42e02c643..74f2037f3 100644
--- a/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml
+++ b/Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml
@@ -19,6 +19,7 @@ properties:
       - qcom,sm6350-adsp-pas
       - qcom,sm6350-cdsp-pas
       - qcom,sm6350-mpss-pas
+      - qcom,sm7250-adsp-pas
 
   reg:
     maxItems: 1
@@ -86,6 +87,7 @@ allOf:
           enum:
             - qcom,sm6350-adsp-pas
             - qcom,sm6350-cdsp-pas
+            - qcom,sm7250-adsp-pas
     then:
       properties:
         interrupts:
@@ -104,6 +106,7 @@ allOf:
         compatible:
           enum:
             - qcom,sm6350-adsp-pas
+            - qcom,sm7250-adsp-pas
     then:
       properties:
         power-domains:

-- 
2.56.0

