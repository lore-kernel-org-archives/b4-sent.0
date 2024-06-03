From: Alexandre Messier <alex@me.ssier.org>
Date: Mon, 03 Jun 2024 02:28:56 -0400
Subject: [PATCH 1/2] dt-bindings: arm: qcom: add HTC One (M8)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-m8-support-v1-1-c7b6a1941ed2@me.ssier.org>
References: <20240603-m8-support-v1-0-c7b6a1941ed2@me.ssier.org>
In-Reply-To: <20240603-m8-support-v1-0-c7b6a1941ed2@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@z3ntu.xyz>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717396145; l=736;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=9wMm6Dj0sMnvRZ2OjIbKpkpq+Ek78nwbjC5uOcxtyfA=;
 b=Ztc9yREx0yJO9Qs7ZsSIzn2Cz05Ma7ndN1uSeLihX8mFU26J3X8hr1T36XJCdoGe8m4UQezt1
 4ls9Pz2emkAB30mkck35Q/Q6SGlPWglFIYZ3K4tm1vkvzY1FCgjgw8l
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible for the HTC One (M8), which is based on the
MSM8974Pro SoC.

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ae885414b181..9a29cc614b6e 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -182,6 +182,7 @@ properties:
       - items:
           - enum:
               - fairphone,fp2
+              - htc,m8
               - oneplus,bacon
               - samsung,klte
               - sony,xperia-castor

-- 
2.45.1

