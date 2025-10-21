From: David Heidelberg <david@ixit.cz>
Date: Tue, 21 Oct 2025 13:53:07 +0200
Subject: [PATCH v4 7/7] dt-bindings: display: panel-simple-dsi: Remove
 Samsung S6E3FC2 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-s6e3fc2x01-v4-7-5e3ee21c688a@ixit.cz>
References: <20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz>
In-Reply-To: <20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1344; i=david@ixit.cz;
 h=from:subject:message-id; bh=c5fkR2jWk5YkcniO/SxqMzx6Ew0swnPogltZcHFgTB8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo93QiJGeCP+WQuzYRJI4TdEzwLRxRfVymzu3Yy
 cuKKbXLmCSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPd0IgAKCRBgAj/E00kg
 clZmEADEDrhcdx28UjTgVPkdnxtUE00Vgeygf8rFA5JPmVtgqJ/0bAE7X0IJJekrhjppGEngSlL
 H2TwD14xpMLAdFV+wu4oFEtudEJXFyeI156Ze2AkBWH6Tc1XHjWgh89KJjsZKmTA9IAY8gd2S3t
 hJ3xgLrQFXMOtaGu7MoI7rrKUU43o3LoHRXg+CF0FHq1K2ck4nXWaqy9sQtJ2pc+zLHTSFud2na
 UC90C2/VxwoVaRugoeTBwCwLwAZM/TxNXjBiNjYlV0Gv7JIiNCp8tKavFcyC6ZCB+T7Af+8SJPv
 pDLLitGYpppyGdi28MAT+juOy/jhKAmI7EAV72gQETQQsiUH1nliO0ENssGwphfhQmOUwijAWKg
 YNrKCRjtLqUai9y0t2TOUGNpyegyj1LCuy5DWzLNTdpwCKIXew7yvVjcr+v3dAUryGYnba6dzI+
 witeJRPxU77NiCLYb7aTd7RqBwH2V+JSb/lsc4WEOVREszMvLmxwew8ATVGXbfH0PJtsSLG9o0R
 1J3+QrJ9hAsgsGwM7zUBfCecb+vNajXCCh5x7HHKHwk8R0VlqEqokY3CGaXYsLXxnY2YBZMhCH9
 4Fwt1ALHkk/zI7OlRa/I/AcCQCUnRXpDtWytxzbAvBiHm1/eX+nBJaRmXwDBYqPugKA3ATLqjjn
 zbk/08wWYl0x0jg==
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
 Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml b/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
index 9b92a05791ccf..ac2db8cf5eb76 100644
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
@@ -80,7 +78,6 @@ allOf:
       properties:
         compatible:
           enum:
-            - samsung,s6e3fc2x01
             - samsung,sofef00
     then:
       properties:

-- 
2.51.0

