From: Xilin Wu <wuxilin123@gmail.com>
Date: Sun, 06 Aug 2023 01:03:11 +0800
Subject: [PATCH 2/3] dt-bindings: arm: qcom: Add Xiaomi Mi 11 Ultra
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230806-xiaomi-star-v1-2-0c384e8b5737@gmail.com>
References: <20230806-xiaomi-star-v1-0-0c384e8b5737@gmail.com>
In-Reply-To: <20230806-xiaomi-star-v1-0-0c384e8b5737@gmail.com>
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1691254992; l=706;
 i=wuxilin123@gmail.com; s=20230805; h=from:subject:message-id;
 bh=QFpbR6ARnfYdwD0jylrDmivrBMUENp37HGfNRpLwt+M=;
 b=5hqHLmqKu5bHc5YAFrMucQeSv18oFrlfAhYWIzNcpGsRFGE4pKXPEIq3CLu///C488gGYQX8N
 o2XmhzVVBMRBROnGsJucAgtITjmmOklK4BKGl/8scJwcWy+DVPmkbiR
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=OZIrHT2qWm7yEdp5fsVR7GsFx1wxciIii20H06Ud088=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20230805 with auth_id=73
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible for Xiaomi Mi 11 Ultra (xiaomi,star).

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 450f616774e0..af69d05ae44a 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -960,6 +960,7 @@ properties:
               - qcom,sm8350-mtp
               - sony,pdx214-generic
               - sony,pdx215-generic
+              - xiaomi,star
           - const: qcom,sm8350
 
       - items:

-- 
2.41.0

