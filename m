From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 30 May 2025 15:35:11 +0800
Subject: [PATCH v2 6/8] dt-bindings: soc: qcom: pmic-glink: Move X1E80100
 out of fallbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250530-qcom_battmgr_update-v2-6-9e377193a656@oss.qualcomm.com>
References: <20250530-qcom_battmgr_update-v2-0-9e377193a656@oss.qualcomm.com>
In-Reply-To: <20250530-qcom_battmgr_update-v2-0-9e377193a656@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748590538; l=1055;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=Cum9h5T8HOEqZYRtn+XVwUsJjYopn4P2b00zD/gfTPk=;
 b=/hIg7NchpOii0i76vHdkSEiRHdTrH5KjZa/MLTucRF+++OFB39/RfeGLaIx+bJr85TDrx6E7U
 Hmyij3OpD+wDfzqRGCIzUykjGLpqVxP+u9ORjXqDHcCI5UqWCdIpxJF
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move X1E80100 out of the fallbacks of SM8550 in pmic-glink support.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
index 4c9e78f29523e3d77aacb4299f64ab96f9b1a831..972bec151118f2e20e1f3b4e0c0a8fbbbea7ab90 100644
--- a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
+++ b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
@@ -39,9 +39,11 @@ properties:
           - enum:
               - qcom,sm8650-pmic-glink
               - qcom,sm8750-pmic-glink
-              - qcom,x1e80100-pmic-glink
           - const: qcom,sm8550-pmic-glink
           - const: qcom,pmic-glink
+      - items:
+          - const: qcom,x1e80100-pmic-glink
+          - const: qcom,pmic-glink
 
   '#address-cells':
     const: 1

-- 
2.34.1

