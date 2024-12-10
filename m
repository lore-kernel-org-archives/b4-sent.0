From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 10 Dec 2024 15:25:26 +0530
Subject: [PATCH 3/4] dt-bindings: vendor-prefixes: Document the 'pciclass'
 prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241210-pci-pwrctrl-slot-v1-3-eae45e488040@linaro.org>
References: <20241210-pci-pwrctrl-slot-v1-0-eae45e488040@linaro.org>
In-Reply-To: <20241210-pci-pwrctrl-slot-v1-0-eae45e488040@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1153;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=HKM4JQvLtVZEuK+wBVjVsihcFTWIsR7scQIFFFt6+xA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnWBAobw0O8/2q4G9PbPmaPc/g7UW2Uo2k1SzXS
 3PtGNLZQbuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1gQKAAKCRBVnxHm/pHO
 9Vo7B/4+lSUrKEPOl/7bJDUkt6FuAdR1edfTmZN3KB1SZp5qApaRRFwAtIMIvvgA/GOKeju0YUU
 Rv/cUXm9VOt+zCJBge69DdtjK1Z4IXtNk/HbtKUVP5aGeH75LdswjMp3Z32rf/55r/c94VtbLu6
 r7k9k+FpeZetGTkuQPtYvPOgLMeV6BOVyda4Iz8LLklkMO1b/46Gt0EuiUHk74DhHrpRSQslKkJ
 hnNcreJ3XDYwCWi1Hl+dNru/3FeBitdHjsW3Hmn8JGvqkJlRo9WGLepFYbEAq9IXb5PE++VMIuH
 yqkD/CWnqYtmjH3HuUHdS1mgn+90zP8odjonKA7zZTVq69FD
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'pciclass' is an existing prefix used to identify the PCI bridge devices,
but it is not a vendor prefix. So document it in the non-vendor prefix
list.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index da01616802c7..0539aea6af5a 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -18,7 +18,7 @@ patternProperties:
   # DO NOT ADD NEW PROPERTIES TO THIS LIST
   "^(at25|bm|devbus|dmacap|dsa|exynos|fsi[ab]|gpio-fan|gpio-key|gpio|gpmc|hdmi|i2c-gpio),.*": true
   "^(keypad|m25p|max8952|max8997|max8998|mpmc),.*": true
-  "^(pinctrl-single|#pinctrl-single|PowerPC),.*": true
+  "^(pciclass|pinctrl-single|#pinctrl-single|PowerPC),.*": true
   "^(pl022|pxa-mmc|rcar_sound|rotary-encoder|s5m8767|sdhci),.*": true
   "^(simple-audio-card|st-plgpio|st-spics|ts),.*": true
 

-- 
2.25.1

