From: Vishal Balasubramanian <vishal.bala.nps@gmail.com>
Date: Wed, 11 Nov 2026 17:54:50 +0530
Subject: [PATCH v2 1/2] dt-bindings: arm: qcom: Add Samsung Galaxy Tab S7
 FE LTE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-master-v2-1-5eb864e9f38d@gmail.com>
References: <20261111-master-v2-0-5eb864e9f38d@gmail.com>
In-Reply-To: <20261111-master-v2-0-5eb864e9f38d@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Vishal Balasubramanian <vishal.bala.nps@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794399891; l=832;
 i=vishal.bala.nps@gmail.com; s=20261111; h=from:subject:message-id;
 bh=9F7my3xYNlAFa6L6qVff7o9I+F4ahR3qE81wL7FFgR8=;
 b=bf0c/fFNhMuA4w66sumeLgVl+d84Sycm7uiyCIuiYCFIvBuiPHwb70Ih0ZVrBglGljP42TgY+
 8pJGRVGkvRQBf/9Plwc2dQTNhFcuggJk3nuCkGdzlLgP2eO18sWkW40
X-Developer-Key: i=vishal.bala.nps@gmail.com; a=ed25519;
 pk=GDcoc+SAK+BHD1Eq17X/BJa9U2HZkBW+dmxS8s1xMAY=
X-Endpoint-Received: by B4 Relay for vishal.bala.nps@gmail.com/20261111 with auth_id=1486
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the compatible for the Samsung Galaxy Tab S7 FE LTE
(SM-T735, codename gts7xllite), a tablet based on the Qualcomm
SM7225 SoC.

Signed-off-by: Vishal Balasubramanian <vishal.bala.nps@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 121ca557ce1effdc95e9e97210bd9a63673f8ba4..abc3c0f53cc14b02d06b68aba3bfd8425ea4fb07 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1118,6 +1118,7 @@ properties:
       - items:
           - enum:
               - fairphone,fp4
+              - samsung,gts7xllite
           - const: qcom,sm7225
 
       - items:

-- 
2.47.3

