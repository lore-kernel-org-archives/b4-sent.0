From: Ishu Brar <patches@brar.si>
Date: Thu, 15 Oct 2026 11:50:40 +0530
Subject: [PATCH] dt-bindings: nvmem: qfprom: Add SM7250 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-qfprom-sm7250-v1-1-2401e54253ad@brar.si>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSQqEQAxA0atI1l2QlFPjVRoXDlHT4FRREcS7W
 +ryLf4/QNkJK2TBAY43URkHD/oEUHXF0LKR2hss2oSQYjM3kxt7o31qYzTfKEyIEJmKGnwzOW5
 kf36//LWu5Z+r5Z7AeV5GCKsucQAAAA==
X-Change-ID: 20261015-qfprom-sm7250-84361100e1ad
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792045241; l=1040;
 i=patches@brar.si; h=from:subject:message-id;
 bh=Js+mOiFMtKojVlFfFjDoASGr/TjMDscmI+GpAAhGGTg=;
 b=sRr5cyL40sr6YpjGeoZpyOQONA6bSYMeVLFmVA+zvDrgLSonGrhZsSfJyMyaySe+WOBlmnLkU
 GE6GYNH4RRLBwoGI4fctMgU+gJcneV614LqWx80R6Q1uJ7nMWdC6n1a
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the qcom,sm7250-qfprom compatible for the fuse block on the
Qualcomm SM7250 SoC. It holds the GPU speed-bin value that selects the
Adreno 620 operating points.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml b/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml
index bc0a0898b..3877b46ff 100644
--- a/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml
+++ b/Documentation/devicetree/bindings/nvmem/qcom,qfprom.yaml
@@ -57,6 +57,7 @@ properties:
           - qcom,sm6115-qfprom
           - qcom,sm6350-qfprom
           - qcom,sm6375-qfprom
+          - qcom,sm7250-qfprom
           - qcom,sm8150-qfprom
           - qcom,sm8250-qfprom
           - qcom,sm8450-qfprom

---
base-commit: f5672a3dff0291d6a45eb0c258b9d2baeb4dc577
change-id: 20261015-qfprom-sm7250-84361100e1ad

Best regards,
--  
Ishu Brar <patches@brar.si>

