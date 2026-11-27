From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Sat, 28 Nov 2026 00:09:23 +0530
Subject: [PATCH v5 03/11] dt-bindings: interrupt-controller: qcom,pdc:
 Document Molokai PDC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-molokai-soc-v5-3-144801dfad7f@yahoo.com>
References: <20261128-molokai-soc-v5-0-144801dfad7f@yahoo.com>
In-Reply-To: <20261128-molokai-soc-v5-0-144801dfad7f@yahoo.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795804762; l=994;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=AtXYB47jpEkNJ5+VdRoyyGnPME6veYsNpY8wyZYc4r8=;
 b=/YghBFxFo22hA80zTV08iEOQ1Fp+D0q5+yLAS7pUKPRddRUw3V6wpPUUYXVYzYqw1WvsiPcmE
 Rl7OWGNUIoxA2b+1QaX5CCAVusPKhh4h97mi+EAFpX+GACHuIL0/7rc
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Power Domain Controller of the Qualcomm Molokai (SM8845) SoC,
which maps one more range of interrupts than the Kaanapali one.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/interrupt-controller/qcom,pdc.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/interrupt-controller/qcom,pdc.yaml b/Documentation/devicetree/bindings/interrupt-controller/qcom,pdc.yaml
index 8401d3b48e0f..64de63b7a031 100644
--- a/Documentation/devicetree/bindings/interrupt-controller/qcom,pdc.yaml
+++ b/Documentation/devicetree/bindings/interrupt-controller/qcom,pdc.yaml
@@ -33,6 +33,7 @@ properties:
           - qcom,kuno-pdc
           - qcom,maili-pdc
           - qcom,milos-pdc
+          - qcom,molokai-pdc
           - qcom,nord-pdc
           - qcom,qcs615-pdc
           - qcom,qcs8300-pdc

-- 
2.56.1

