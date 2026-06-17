From: Haritha S K <haritha.k@oss.qualcomm.com>
Date: Wed, 17 Jun 2026 10:04:24 +0530
Subject: [PATCH] dt-bindings: thermal: qcom-tsens: Document the maili
 Temperature Sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-b4-maili-upstream-3-v1-1-1b8cb7e425d8@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAM8jMmoC/yXMTQqEMAxA4atI1hOwOhQ7V5FZpE7UyPhDoyKId
 7fq8lu8t4NyEFb4JDsEXkVlHCLMK4GqpaFhlF80ZGlmU2ss+jf2JH/BZdI5MPWYozeuIKLCWVd
 DLKfAtWz3tfw+1sV3XM3XCo7jBEFi7Md3AAAA
X-Change-ID: 20260616-b4-maili-upstream-3-b198aaa8969f
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
 Haritha S K <haritha.k@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781670871; l=998;
 i=haritha.k@oss.qualcomm.com; s=20260422; h=from:subject:message-id;
 bh=QERCdXGosQegGLSoxEuG9NnIUKptP7q6k2ZKHvSRHas=;
 b=WAotvr0uQcjTXhUxvjBHdPDShW9EAAwzrDzxorB7YjD+4SbubRzRH12mhY67qkUAsKJrpgBOH
 yveHkcYVqh7BLc2W1oKlUfxaVrBbi/gxPisO0eOnLjmdAx71izFrH6F
X-Developer-Key: i=haritha.k@oss.qualcomm.com; a=ed25519;
 pk=ivp2P9RgsC6IkOe8JaqweeahT9pd0BVtL2d1YD8ICSg=
X-Endpoint-Received: by B4 Relay for haritha.k@oss.qualcomm.com/20260422 with auth_id=745
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Temperature Sensor (TSENS) on the Qualcomm maili SoC.

Signed-off-by: Haritha S K <haritha.k@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
index f0efaa8349ee..5a8f7673e730 100644
--- a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
+++ b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
@@ -58,6 +58,7 @@ properties:
               - qcom,glymur-tsens
               - qcom,hawi-tsens
               - qcom,kaanapali-tsens
+              - qcom,maili-tsens
               - qcom,milos-tsens
               - qcom,nord-tsens
               - qcom,msm8953-tsens

---
base-commit: a76326dca329a7a738ba367529868dfbafb4a403
change-id: 20260616-b4-maili-upstream-3-b198aaa8969f

Best regards,
--  
Haritha S K <haritha.k@oss.qualcomm.com>

