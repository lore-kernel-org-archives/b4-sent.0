From: David Heidelberg <david@ixit.cz>
Date: Mon, 08 Dec 2025 10:41:54 +0100
Subject: [PATCH v6 1/8] dt-bindings: arm: qcom: Add Pixel 3 and 3 XL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251208-pixel-3-v6-1-e9e559d6f412@ixit.cz>
References: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
In-Reply-To: <20251208-pixel-3-v6-0-e9e559d6f412@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Petr Hodina <phodina@protonmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=765; i=david@ixit.cz;
 h=from:subject:message-id; bh=Vnt/xXHh7c01EXNWnpunAXvFyH2vLjx4UfYXxFc1+5w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNp1/qlP6M4fA/UAI9sFslieZ/vPbVdIWRdnrw
 sNMRGePcV+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTadfwAKCRBgAj/E00kg
 csCCD/9pw77H//blcdVh47TCMq5x3u0geMj+edvvECKlk1jqZQkeDoAACyJKOxWFTIesWIihVG9
 G8iNdshQeUF2v/ODkPkeCrM8iVbYbMzz/V7wBIxwJreiTM/FOQlcDJzfKC/0oscYQ+Rns+Kc2RL
 OjZgwCgBMy0JH3e6OVo9fWxyYJ4CjjLOhBIOxdiDgbq6xXXXuhEhL5QuRADK5bsAnlbmk2ere6o
 Wfpv41N7OPAape7rCm+Klcal8c+tVLH3yHU0sj7wfnssL+GF5vIARAGDN/wmubUf7VOtLpddnAU
 imeOPaDTfB6ewq4t9N00Me4+KXoWGz6MtabP2sWj/qDi9oj3fpdMJq2D20QgY61qfIEcE3mLZc7
 jdaufFk7fz3sVnPBMcioC8umAOmFNvfZJ+VmenataKIMUIxyiICtodu6wIpDUXZ7nHjlYinhhCA
 GLZ0gQvSdSOUcSc7K+yvhFRQpHbQ7zpkNjuIIHTKIMZWM8sQGKH3ThDmJRSLKyf+2V4f/9gR2Ad
 C9Bt3mt5jGaBwH3YgDUzxBMFHu/m+uwrx61IE7HduThDRQOGxcFho0h6I/P4WWHPE/63/R3SOs9
 5WIh6N3R0XbQQaPZ9AZAKIBRML8H1boVMp7kGShdvXXxAkwMqpSdeatqYVgtavpi4W8S6/Eyr7M
 QjAetK403TJj8dQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the bindings for the Pixel 3 and 3 XL.

Acked-by: Krzysztof Kozlowski <krzk@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d84bd3bca2010..760b6633b7a55 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -900,6 +900,8 @@ properties:
 
       - items:
           - enum:
+              - google,blueline
+              - google,crosshatch
               - huawei,planck
               - lenovo,yoga-c630
               - lg,judyln

-- 
2.51.0

