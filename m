From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Sat, 20 Dec 2025 01:21:58 +0100
Subject: [PATCH v5 1/7] dt-bindings: arm: qcom: Document Microsoft Surface
 Pro 11
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251220-surface-sp11-for-next-v5-1-16065bef8ef3@gmail.com>
References: <20251220-surface-sp11-for-next-v5-0-16065bef8ef3@gmail.com>
In-Reply-To: <20251220-surface-sp11-for-next-v5-0-16065bef8ef3@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Maximilian Luz <luzmaximilian@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, ath12k@lists.infradead.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Dale Whinham <daleyo@gmail.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766190155; l=1642;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=czM+TPxOMMiJH/Gt+R3N8HrTMAEgGVZ3NK5XzhGpukM=;
 b=cdISlgxs1gJARTGX0ApnqNF3+49M9po5+ZCq1lrGxdMn8SKMBhPy793eizGxpQJZrBzcgdRHN
 5PcwByfm2tuC3/VQAxQ340uc4tpc2DMNcqcJZkZ9++rvvu25d/NaSLj
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatibles for the Qualcomm-based Microsoft Surface Pro 11,
using its Denali codename.

The LCD models are using the Qualcomm Snapdragon X1 Plus (X1P64100),
the OLED ones are using the Qualcomm Snapdragon X1 Elite (X1E80100).

Due to the difference in how the built-in panel is being handled
between the OLED variant and LCD one, it is required to have two
separate DTBs, so document the compatible string for both variants.

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d84bd3bca2010508a8225b9549d8c634efa06531..4e94776b8c4cd915d7779628c005a021d27aab63 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1067,6 +1067,12 @@ properties:
           - const: qcom,x1e78100
           - const: qcom,x1e80100
 
+      - items:
+          - const: microsoft,denali-lcd
+          - const: microsoft,denali
+          - const: qcom,x1p64100
+          - const: qcom,x1e80100
+
       - items:
           - enum:
               - asus,vivobook-s15
@@ -1089,6 +1095,11 @@ properties:
           - const: qcom,hamoa-iot-som
           - const: qcom,x1e80100
 
+      - items:
+          - const: microsoft,denali-oled
+          - const: microsoft,denali
+          - const: qcom,x1e80100
+
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa-lcd

-- 
2.47.3

