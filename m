From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 23 Nov 2024 12:05:51 +0100
Subject: [PATCH 1/4] dt-bindings: display: panel: samsung,atna56ac03:
 Document ATNA56AC03
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241123-asus_qcom_display-v1-1-85a9ff9240aa@hotmail.com>
References: <20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com>
In-Reply-To: <20241123-asus_qcom_display-v1-0-85a9ff9240aa@hotmail.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732359972; l=1104;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=IsotGGeS1hNHslMt3hu9mke2nzQXlgG9kOU5FgNZHkA=;
 b=1bY5DkY93Gn2mdw2OBx6WTL8VTBKNeT3HFOhpT8r+4u8hC0+0oqU8R90hvLidqgDuSddYjwvG
 Ehq72DVIwbcB6gHQU7y25tEaXYlQNutH7A3Lq5VbMEosZmFmZwKnQfd
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung ATNA56AC03 panel is an AMOLED eDP panel.
It is similar to the ATNA33xc20 except it is larger
and has a different resolution.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 Documentation/devicetree/bindings/display/panel/samsung,atna33xc20.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/samsung,atna33xc20.yaml b/Documentation/devicetree/bindings/display/panel/samsung,atna33xc20.yaml
index 032f783eefc4508df35da10e53ca20ff8b1b9bdf..684c2896d2387077cf2d91cc5a025e0838c0f536 100644
--- a/Documentation/devicetree/bindings/display/panel/samsung,atna33xc20.yaml
+++ b/Documentation/devicetree/bindings/display/panel/samsung,atna33xc20.yaml
@@ -23,6 +23,8 @@ properties:
               - samsung,atna45af01
               # Samsung 14.5" 3K (2944x1840 pixels) eDP AMOLED panel
               - samsung,atna45dc02
+              # Samsung 15.6" 3K (2880x1620 pixels) eDP AMOLED panel
+              - samsung,atna56ac03
           - const: samsung,atna33xc20
 
   enable-gpios: true

-- 
2.47.0

