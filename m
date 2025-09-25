From: David Heidelberg <david@ixit.cz>
Date: Thu, 25 Sep 2025 11:12:48 +0200
Subject: [PATCH 2/8] dt-bindings: display: panel-simple-dsi: Remove Samsung
 S6E3FC2 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-s6e3fc2x01-v1-2-9293016768f7@ixit.cz>
References: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
In-Reply-To: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1082; i=david@ixit.cz;
 h=from:subject:message-id; bh=xZd51QEp65zXenV7/weNa8nwNn4FJHjaNfLFDRzKpTY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo1QeRn2Lir6+rXOxzR2h4llPHCW6H4qaP3XqUZ
 03vof9rvSOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNUHkQAKCRBgAj/E00kg
 csBiD/0cD2A2cgc0/Vq86T5j/9JT7LnDZfIHiTGmn+y8m8oaCgWh/cu6KdzinjZcaXrMnmnezKv
 IaMzyqCyUWCmQEewkF2L8vSqDCqBvdExJA4r+xuqqLCT0NG/eBzvIcgilITFwIIa/M+g3AewC8K
 lKTkkVPt2OPEYYIhMOIfxykHrpcD65yFOZ2lcVJIRGbvFPZqdt2ZneEjJXC9p/c+Fn01XcVwwZF
 vb7LmbPzXLFH3BgUVhxwbevU7EjIYikIvb4hRrQM5dAALjEVBtTwy4HzEaqOdnS2QRHKBZe/cF7
 F/RMWTNnnpSrXcBZgJPIK7aUG6/Yj3mtBLikddBSnNVknAakALmlXv0EteNDCPGDMBi3JegQZEk
 qdFHmQ0NJCmazumLoG6ovGC5g1VdPZx7eN4CmilhMbkKZrQOR/RnYBFs1HmG6DawjzFB/Tjw0ST
 mPTZQsJjATqVwPvQ0nWOofDcLdp6iTvQb5xwO6OAshYVQfSmc423gCtIUnbI2ZFk5pueYuua+Rh
 xKmaAl/CsdstBnR8P27ZPsa0erdIjCZO/jwSfn7s1WU8B9X+phKwb2PWyotAo4/XuAmwLmdrYAg
 37EnsB1CIQvAt0wVJNjPJd/fG4bV+WoPQrLPHYcUIjYMVfhdquLofFyeWdoOEzp8RcsKj9PJTIY
 2pSXJX9MVisD6yQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Follow up commit introduce the proper device tree definition for the DDIC.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml | 2 --
 1 file changed, 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml b/Documentation/devicetree/bindings/display/panel/panel-simple-dsi.yaml
index 9b92a05791ccf99061ab7a1e01937bb832a96fe6..6c1249a224c8a170b33fd3f331f985f16914cb2c 100644
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

