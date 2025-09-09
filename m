From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 09 Sep 2025 19:02:33 +0200
Subject: [PATCH v8 1/3] dt-bindings: arm: qcom: Add HP Omnibook X14 AI
 X1P4200 variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-hp-x14-x1p-v8-1-8082ab069911@oldschoolsolutions.biz>
References: <20250909-hp-x14-x1p-v8-0-8082ab069911@oldschoolsolutions.biz>
In-Reply-To: <20250909-hp-x14-x1p-v8-0-8082ab069911@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757437358; l=1044;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=Q/61I5/AK1HbfYRX0KWha99BihztwFSAKt8iv2F7lF8=;
 b=nNjSbkmMCtq7EG6ONxhQ9P8D7y7hJGNwp+sV9l9tUakD1WVT+R7JxMbzRVhx/Uz1gEp4nwRps
 P7OeVItQzkXAu151EkL5GULpB8mlXu35IswtXHr6fgBS8BFEHRl2YP5
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Omnibook X14 AI PC is available in fe0 (Hamoa, x1e80100) and
fe1 (Purwa, x1p42100) SKUs. Since they are not completely dtb-compatible,
add another variant:

hp,omnibook-x14-fe1 compatible to cqom,x1p42100

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 7d47d0c04376bc2d4802b55e7121573df472a3c4..916217c7996d9a7adde0355dbbf246e251694ad4 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1076,6 +1076,7 @@ properties:
       - items:
           - enum:
               - asus,zenbook-a14-ux3407qa
+              - hp,omnibook-x14-fe1
               - lenovo,thinkbook-16
               - qcom,x1p42100-crd
           - const: qcom,x1p42100

-- 
2.48.1

