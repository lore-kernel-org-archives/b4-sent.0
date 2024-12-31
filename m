From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 31 Dec 2024 15:13:46 +0530
Subject: [PATCH v2 5/6] dt-bindings: vendor-prefixes: Document the
 'pciclass' prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241231-pci-pwrctrl-slot-v2-5-6a15088ba541@linaro.org>
References: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
In-Reply-To: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1265;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=2V7zx2KeHk/VkOVQ7/eUdxe/lfsvltP4xYw5h/bK3Jg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnc7zrdciV1jQWsadhJ4t7js4Cn7Ak714NgV2do
 SpaQY946HaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ3O86wAKCRBVnxHm/pHO
 9Ww/B/wNerD31lCjE4OJmIqxQWZOqcYw66Ta2d/3+wwFEIL6JD4t1JgG2jL4MpUM78L0AcQO1VD
 ga8zNq0guDXRBO9DiyWZnziUcnARZccKeQ0uJD/Jtd937noG2D9fAld8rE9pePmYTCJLG821BO0
 4N0V/jwr2uE6kxDFFU5flAp/65B8TMAstqX8ztjzDclxDWsrd9kTcnaPeJmvHuxYBFT6ChUtswZ
 H+1RImAANVNEIJfCP1UICzTDIoZDRE4qOAb2aUVTYAoDFdSh2oEtNv/FrGgWmMtuz0UYhux0e3C
 CneMG3xbsj2tInJeElO3YgsFrFHMxHdaMAkQTa/4EWQDc3bM
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

