From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Fri, 20 Sep 2024 19:47:25 +0200
Subject: [PATCH v2 2/2] dt-bindings: arm: qcom: Add Microsoft Windows Dev
 Kit 2023
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240920-jg-blackrock-for-upstream-v2-2-9bf2f1b2191c@oldschoolsolutions.biz>
References: <20240920-jg-blackrock-for-upstream-v2-0-9bf2f1b2191c@oldschoolsolutions.biz>
In-Reply-To: <20240920-jg-blackrock-for-upstream-v2-0-9bf2f1b2191c@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Merck Hung <merckhung@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726854445; l=743;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=6wRSNxIph3/qSJRgFI6zNdBzJg2ZkmeHrrkm08D757I=;
 b=Ppcbw1ZBVtgy6EykM9PdkoSciMcXAJkUwDpu42Q7pxQAD/BM68+EbOG36QEy86ztlrcN7SzZH
 yn67FO+fI18Bm/QGdOVL2TaisMH5m3qUagZI2tPd7X3g7n3nVAtFJhd
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible values for WDK2023 with its codename "blackrock"

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index f08e13b61172..cbff0313155e 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -812,6 +812,7 @@ properties:
               - lenovo,thinkpad-x13s
               - qcom,sc8280xp-crd
               - qcom,sc8280xp-qrd
+              - microsoft,blackrock
           - const: qcom,sc8280xp
 
       - items:

-- 
2.43.0

