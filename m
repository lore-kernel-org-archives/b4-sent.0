From: Dipa Ramesh Mantre <dipa.mantre@oss.qualcomm.com>
Date: Tue, 12 May 2026 16:43:36 +0530
Subject: [PATCH] dt-bindings: thermal: qcom-tsens: Document the Hawi
 Temperature Sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-dtbinding-hawi-v1-1-96149d06cccf@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAF8LA2oC/x3MQQqAIBBA0avErBPUMLCrRAvTUWdjoVGBePek5
 Vv8X6FgJiywDBUy3lToSB1iHMBGkwIyct0guZy5EpK5a6fkKAUWzUOMW++1cEr5SUOPzoye3n+
 4bq19fdQfvWAAAAA=
X-Change-ID: 20260512-dtbinding-hawi-0cff91d55f39
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 manaf.pallikunhi@oss.qualcomm.com, gaurav.kohli@oss.qualcomm.com, 
 Dipa Ramesh Mantre <dipa.mantre@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778584419; l=995;
 i=dipa.mantre@oss.qualcomm.com; s=20260415; h=from:subject:message-id;
 bh=KOQ0xKaM2gpSifvcaPimSMSf2hpELPm2eIvMUK4YQpE=;
 b=rXhPDH9HDtxmlzKe2QNLiJ5FOTq62qlnuEqZjTPLFbZelHTpVqb/fm8DfNrPOB9NuV+B/SGeM
 tuG8TYpq/s5DVrlKRcV6AvgfPBFEU0ijGVvtWpxGp3TtV3RfbXj8Sso
X-Developer-Key: i=dipa.mantre@oss.qualcomm.com; a=ed25519;
 pk=IcrgHu2jFHNILPVydQwFqCQq05WcA8wBixw5s+yRMVI=
X-Endpoint-Received: by B4 Relay for dipa.mantre@oss.qualcomm.com/20260415 with auth_id=736
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Temperature Sensor (TSENS) on the Qualcomm Hawi SoC.

Signed-off-by: Dipa Ramesh Mantre <dipa.mantre@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
index 7d34ba00e684..4fce027e44ad 100644
--- a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
+++ b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
@@ -56,6 +56,7 @@ properties:
           - enum:
               - qcom,eliza-tsens
               - qcom,glymur-tsens
+              - qcom,hawi-tsens
               - qcom,kaanapali-tsens
               - qcom,milos-tsens
               - qcom,msm8953-tsens

---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260512-dtbinding-hawi-0cff91d55f39

Best regards,
-- 
Dipa Ramesh Mantre <dipa.mantre@oss.qualcomm.com>

