From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 19 May 2026 09:16:32 +0200
Subject: [PATCH v3 2/8] dt-bindings: extcon: qcom,pm8941-misc: Add PM8921
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-mainline-send-v1-sending-v3-2-3dd7aa125353@alex-min.fr>
References: <20260519-mainline-send-v1-sending-v3-0-3dd7aa125353@alex-min.fr>
In-Reply-To: <20260519-mainline-send-v1-sending-v3-0-3dd7aa125353@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Kees Cook <kees@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 iommu@lists.linux.dev, phone-devel@vger.kernel.org, 
 Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779174999; l=1917;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=vqyH0stw0peI1PfW63PuN6liDgMjrgI82QMhyQ70tz8=;
 b=kfGk6oeX1jcJazd0LrLbLbrKjzAeHCn17Gykl81HwU6hC/n4HYIMy2AS3EA5AlZ+BjCHH8ps1
 2ZjakS2tToND/apPmb78Ssbk/V6ztUhGMdI2raQwI77ABYN+r11BrEW
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PM8921/PM8821 provide USB ID detection through the PMIC USB block. The
USB_ID_IN interrupt is exposed by the PM8921 interrupt controller and is
used by APQ8064 platforms for OTG role detection.

The device is modeled as a child of the SSBI-connected PM8921 PMIC.
Unlike PM8941, the downstream PM8xxx misc device is not instantiated with
a register resource for this path, and the mainline extcon driver only
needs the named USB ID interrupt. Allow qcom,pm8921-misc without requiring
reg.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 .../devicetree/bindings/extcon/qcom,pm8941-misc.yaml    | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/extcon/qcom,pm8941-misc.yaml b/Documentation/devicetree/bindings/extcon/qcom,pm8941-misc.yaml
index 6b80518cbf62..4e3d0aadb83c 100644
--- a/Documentation/devicetree/bindings/extcon/qcom,pm8941-misc.yaml
+++ b/Documentation/devicetree/bindings/extcon/qcom,pm8941-misc.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/extcon/qcom,pm8941-misc.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Qualcomm Technologies, Inc. PM8941 USB ID Extcon device
+title: Qualcomm Technologies, Inc. PMIC USB ID Extcon device
 
 maintainers:
   - Guru Das Srinagesh <quic_gurus@quicinc.com>
@@ -15,8 +15,9 @@ description: |
 
 properties:
   compatible:
-    items:
-      - const: qcom,pm8941-misc
+    enum:
+      - qcom,pm8921-misc
+      - qcom,pm8941-misc
 
   reg:
     maxItems: 1
@@ -37,10 +38,18 @@ properties:
           - const: usb_vbus
 required:
   - compatible
-  - reg
   - interrupts
   - interrupt-names
 
+allOf:
+  - if:
+      properties:
+        compatible:
+          const: qcom,pm8941-misc
+    then:
+      required:
+        - reg
+
 additionalProperties: false
 
 examples:

-- 
2.43.0

