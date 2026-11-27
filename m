From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Sat, 28 Nov 2026 00:09:27 +0530
Subject: [PATCH v5 07/11] dt-bindings: arm: qcom: Document Molokai and the
 Motorola Signature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-molokai-soc-v5-7-144801dfad7f@yahoo.com>
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
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795804762; l=883;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=EMR0bzongKtYLt4CKK8C1JzDACXZlOzy7AkZudtfYqk=;
 b=jnAtDOllGON+vnbBemjhgU2LP7G+Mk9FM/6muYEMMyoPcxKkReyBUQFLaFV64cFRMwQnYkIfu
 IbNCr03AqEzBTFkf894xxB1ot+YFhWS226p0ye6vRxuxbQi72pv0JCI
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Qualcomm Molokai (SM8845) SoC and the Motorola Signature
(vantage) phone based on it.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Reviewed-by: Krzysztof Kozlowski <krzk@kernel.org>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 7ffa4f69987f..6993bbffef9e 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -241,6 +241,11 @@ properties:
               - nothing,asteroids
           - const: qcom,milos
 
+      - items:
+          - enum:
+              - motorola,vantage
+          - const: qcom,molokai
+
       - items:
           - enum:
               - microsoft,dempsey

-- 
2.56.1

