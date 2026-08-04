From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 04 Aug 2026 08:34:26 +0200
Subject: [PATCH v5 1/6] dt-bindings: arm: qcom: Add Samsung Galaxy S4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mainline-send-v1-sending-v5-1-149dd4372ac8@alex-min.fr>
References: <20260804-mainline-send-v1-sending-v5-0-149dd4372ac8@alex-min.fr>
In-Reply-To: <20260804-mainline-send-v1-sending-v5-0-149dd4372ac8@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Lee Jones <lee@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 phone-devel@vger.kernel.org, Alexandre MINETTE <contact@alex-min.fr>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785825291; l=854;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=Lrgs0k4d0tyivYZbLbwfL0EK902GKco2rWAQQHTAiDQ=;
 b=acZYbIF9bHPvxd09sQmA3y6EGuJD/ggmJG3yTP7nnvfC7Svgd0recCie+slOO2gsG+4fb0jzl
 F+FWC5lYXZZAAU+uQ0e2zZ0EH3+1KxJ4MRGJnuiplNbIi/sOLFgCi6p
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for the Qualcomm APQ8064-based Samsung Galaxy S4,
codenamed jflte.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index b4943123d2e4..b7e186ed2efc 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -39,6 +39,7 @@ properties:
           - enum:
               - asus,nexus7-flo
               - lg,nexus4-mako
+              - samsung,jflte
               - sony,xperia-yuga
               - qcom,apq8064-cm-qs600
               - qcom,apq8064-ifc6410

-- 
2.43.0

