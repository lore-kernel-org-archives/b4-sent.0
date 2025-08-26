From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Tue, 26 Aug 2025 15:18:33 +0800
Subject: [PATCH v3 6/8] dt-bindings: soc: qcom,pmic-glink: Add charge limit
 nvmem properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250826-qcom_battmgr_update-v3-6-74ea410ef146@oss.qualcomm.com>
References: <20250826-qcom_battmgr_update-v3-0-74ea410ef146@oss.qualcomm.com>
In-Reply-To: <20250826-qcom_battmgr_update-v3-0-74ea410ef146@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 =?utf-8?q?Gy=C3=B6rgy_Kurucz?= <me@kuruczgy.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756192715; l=1445;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=ORlAVczHQEA0etBKQz2CENwDXUZXd+9EuSntaMi9ZEE=;
 b=h48ys0f+qEB7+0uoFBLr92/XOO7t0htNP1CHWOiYkdaL5AJMU/ZtZxF0qrfgA+gMUrD7lbn/O
 p92TpiOpK2QAiirfCQsuKD8nqztmnaapvAua+H64T17OyqHbnXYXVgc
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add nvmem properties to retrieve charge control configurations
from the PMIC SDAM registers.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 .../devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml      | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
index 4c9e78f29523e3d77aacb4299f64ab96f9b1a831..9d6db4825da389aa14d77f653d2f8a3442e22162 100644
--- a/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
+++ b/Documentation/devicetree/bindings/soc/qcom/qcom,pmic-glink.yaml
@@ -55,6 +55,20 @@ properties:
       The array should contain a gpio entry for each PMIC Glink connector, in reg order.
       It is defined that GPIO active level means "CC2" or Reversed/Flipped orientation.
 
+  nvmem-cells:
+    minItems: 3
+    maxItems: 3
+    description:
+      The nvmem cells contain the charge control settings, including the charge control
+      enable status, the battery state of charge (SoC) threshold for stopping charging,
+      and the battery SoC delta required to restart charging.
+
+  nvmem-cell-names:
+    items:
+      - const: charge_limit_en
+      - const: charge_limit_end
+      - const: charge_limit_delta
+
 patternProperties:
   '^connector@\d$':
     $ref: /schemas/connector/usb-connector.yaml#

-- 
2.34.1

