From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 16 Jan 2025 19:39:14 +0530
Subject: [PATCH v3 4/5] dt-bindings: vendor-prefixes: Document the
 'pciclass' prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-pci-pwrctrl-slot-v3-4-827473c8fbf4@linaro.org>
References: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
In-Reply-To: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1265;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=2V7zx2KeHk/VkOVQ7/eUdxe/lfsvltP4xYw5h/bK3Jg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBniRMMqJ0tFL1peWsFLw0JQ+t/mHBHcnihGGU48
 F8Ntj+NYuGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ4kTDAAKCRBVnxHm/pHO
 9bDiB/sFmV0721mpAS6mcUNEEuysd2O2czSfvdXp8zeE842N+e8avzu+V/c+dPfFUWAzXWHFmi6
 R1CBNjbE7AhVmFL7aifhF2eKs1FJIFHOnRtAUfTzz5X5Wo2/xN0D2vNenPADyKeToBlT8yKC9Oa
 9y50Eb0h5XuY0Zz7OpoNwW7W2yyEfvQMgcYcbMfE+VxbL68nz0NiTTZDGIuTPFMuZf1ViW/WbEq
 ieMgOd/LSU2v9vv3CFFB7n+YUnKOEM5rbIx74oSY1pT/juA9GyuNWDIykXSz3XPt8QC5gcIgyc/
 l07moVEZhmqkf6kYwZVQmtENLHQb1nBcRd5XXNCPZhD29P2y
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'pciclass' is an existing prefix used to identify the PCI bridge devices,
but it is not a vendor prefix. So document it in the non-vendor prefix
list.

Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Acked-by: Rob Herring (Arm) <robh@kernel.org>
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

