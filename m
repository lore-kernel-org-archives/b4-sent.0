From: Xilin Wu <wuxilin123@gmail.com>
Date: Sat, 21 Oct 2023 18:20:39 +0800
Subject: [PATCH v2 2/3] dt-bindings: arm: qcom: Add Xiaomi Mi 11 Ultra
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231021-sakuramist-mi11u-v2-2-fa82c91ecaf0@gmail.com>
References: <20231021-sakuramist-mi11u-v2-0-fa82c91ecaf0@gmail.com>
In-Reply-To: <20231021-sakuramist-mi11u-v2-0-fa82c91ecaf0@gmail.com>
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Xilin Wu <wuxilin123@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1697883643; l=772;
 i=wuxilin123@gmail.com; s=20231021; h=from:subject:message-id;
 bh=VL47L5WkxMWPPZ+BX+QGqUKBGAfsfYVuR4G6B/leYYw=;
 b=GzlVDebY/l0zmDpd4Wp4s4VnxIk8ViKKaoJzcoq/+n3r7AmTyZo1lMTAB5oR/AgtILHL97SPI
 60go7ZPW4swDAobWcYSIPc8GBBqL+StGbFQV9olRHWvhNYjqWO0P2nu
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=edoFbrGewAWr5/CxptHll7XzvXBjYiN49RrEgipi1Cg=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20231021 with auth_id=89
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible for Xiaomi Mi 11 Ultra (xiaomi,star).

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 7f80f48a0954..35f7a96f0652 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1018,6 +1018,7 @@ properties:
               - qcom,sm8350-mtp
               - sony,pdx214-generic
               - sony,pdx215-generic
+              - xiaomi,star
           - const: qcom,sm8350
 
       - items:

-- 
2.42.0

