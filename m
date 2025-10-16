From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 18:17:03 +0200
Subject: [PATCH v3 8/8] dt-bindings: display: panel-simple-dsi: Remove
 Samsung S6E3FC2 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-s6e3fc2x01-v3-8-ce0f3566b903@ixit.cz>
References: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
In-Reply-To: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1158; i=david@ixit.cz;
 h=from:subject:message-id; bh=4+Nx6clkhCkST//F+2BMd0nBGtyNIXUCEfb23utzTYI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp5wt2y0Xc1+GKJ2t1MY4XOuvPZTZP7bPEqj
 ByfvV+qXciJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 clAqEACCZWBWo0npnp0kidoPHG1Pd/dBw56Sdxumg+7kDxKkJfyDDdLxF/y48pxHpeBvbyINosc
 5v3HFOzDHjiBQRQMcg/sP2rr18XF6B0U4h03JqtLbaT7F6+C9UpUz+mxNmePtIz2rvn4mzNa/Ln
 gATpba3HePKXgXnGiIvBavkGW7EsQsSjiu4x2o9NbqSdE73w3tfbyCMVpdst6iXhWJLpyfH8iX5
 vxhNnr6zMZLUKidz2R/FwC0HnYE1yFU5XtUFt7bWJYh9O8SmneXpnLPKrBTH95GJVJEmvFQgtoO
 KXWLDfk2p5ZOAvIF977zt0GHzmljRvFkdhRwhXq1qfMN+HaO9IzqyIaAV8igUB548ujoguRn2Gs
 FlcN4XDl+EqaCGYZp4WjzbKwou57szMjuvFypcXxIyrIwhOR+/HPw8b7kRH1L8Sg2+FuOeEZAq4
 fgPYxtYbEaWi/dMNvJe3Bid/uymgELyqAbBhpL1gjLwznIxqJ6RGPOOjvLUU/Uk3pPwgsx1Brm4
 Cd209RKQxjTwKL8OfnBwqd1Krts46M4FPDyZXdZmgkHFRl5XFBgDXGa4A8WY80U0nHkoOvQGV3J
 KmQ/mcJenWBqi2NgUszoRJAiPBCbQCmEDF/Yfs+StH5zzoyVn1iZ51fuPyO6eQGT1MGgFCgcdAW
 KRMl6fLfDTNCrNg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Samsung S6E3FC2X01 DDIC isn't Simple DSI panel.

This panel has three supplies, while panel-simple-dsi is limited to one.
There is no user of this compatible, nor the compatible make sense.
Remove it.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml | 2 --
 1 file changed, 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml b/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
index 9b92a05791ccf..6c1249a224c8a 100644
--- a/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
+++ b/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
@@ -56,8 +56,6 @@ properties:
       - panasonic,vvx10f034n00
         # Samsung s6e3fa7 1080x2220 based AMS559NK06 AMOLED panel
       - samsung,s6e3fa7-ams559nk06
-        # Samsung s6e3fc2x01 1080x2340 AMOLED panel
-      - samsung,s6e3fc2x01
         # Samsung sofef00 1080x2280 AMOLED panel
       - samsung,sofef00
         # Shangai Top Display Optoelectronics 7" TL070WSH30 1024x600 TFT LCD panel

-- 
2.51.0

