From: Robin Snyders <robin@snyders.xyz>
Date: Tue, 11 Aug 2026 22:35:04 +0200
Subject: [PATCH 1/3] dt-bindings: power: supply: qcom,pmi8998-charger: add
 SMB5 PMICs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-submit-qcom-smbx-send-v1-v1-1-feec6cfa123a@snyders.xyz>
References: <20260811-submit-qcom-smbx-send-v1-v1-0-feec6cfa123a@snyders.xyz>
In-Reply-To: <20260811-submit-qcom-smbx-send-v1-v1-0-feec6cfa123a@snyders.xyz>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robin Snyders <robin@snyders.xyz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786480511; l=939;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=EYGMyPfkRuuk1QHQrRSaTrAt/JZBY5TFPUfwjprLJoo=;
 b=2zjhn0rcir35V690AgI3vmDGAQrUmO7XzcAqZ+hVyAZytBBhtfX27vBplyTSo98tY/LqROTKm
 yfITkTgkAncCRUOYpk9JJD3BerrASJ/Qgk3rQA2AMeerhPIc46udQEt
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Add compatible strings for PM7250B and PM8150B, which contain the SMB5
generation of the Qualcomm switch-mode battery charger.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 .../devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml          | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
index 70f5cd6eaeab..9e200ba3f3a8 100644
--- a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
@@ -12,6 +12,8 @@ maintainers:
 properties:
   compatible:
     enum:
+      - qcom,pm7250b-charger
+      - qcom,pm8150b-charger
       - qcom,pmi8998-charger
       - qcom,pm660-charger
 

-- 
2.54.0

