From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sun, 24 Nov 2024 14:20:15 +0100
Subject: [PATCH 1/4] dt-bindings: arm: qcom: Add HP Omnibook X 14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241124-hp-omnibook-x14-v1-1-e4262f0254fa@oldschoolsolutions.biz>
References: <20241124-hp-omnibook-x14-v1-0-e4262f0254fa@oldschoolsolutions.biz>
In-Reply-To: <20241124-hp-omnibook-x14-v1-0-e4262f0254fa@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Kalle Valo <kvalo@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732454418; l=935;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=XL2QR5fav9PTm4bj2aAabfeiNRaT7RhXzBiXmBI/OBE=;
 b=vlJcJ1R6tCoInUkDdhDqzBlrIKNw4mub3QTLW0OBoLbgBex8YvyWkUGcNgnkaj5u/zmvGgWDS
 Mq7S26+sOkaCafSSuDYtrliqEzfC8RMLYx1YLXyoqtZBPgNeEn30cYy
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible values for the HP Omnibook X Laptop 14-fe0750ng,
using "hp,omnibook-x14"

The laptop is based on the Snapdragon X Elite (x1e80100) SoC.

PDF link: https://www8.hp.com/h20195/V2/GetPDF.aspx/c08989140

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index ca39903935104..62e197a1e7603 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1103,6 +1103,7 @@ properties:
           - enum:
               - asus,vivobook-s15
               - dell,xps13-9345
+              - hp,omnibook-x14
               - lenovo,yoga-slim7x
               - microsoft,romulus13
               - microsoft,romulus15

-- 
2.43.0

