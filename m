From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:06 +0530
Subject: [PATCH v3 03/13] dt-bindings: PCI: pci-ep: Update Maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-3-a1426afdee3b@linaro.org>
References: <20240731-pci-qcom-hotplug-v3-0-a1426afdee3b@linaro.org>
In-Reply-To: <20240731-pci-qcom-hotplug-v3-0-a1426afdee3b@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=1035;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=5QyilnsJ9fmtdU7GTZXO3WdPGs0Omyndpvk9fplsO9U=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbiWXLtJTjlNETMDM7azE6UNNZ/+BSyYNgB2
 PM0PCX5slWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW4gAKCRBVnxHm/pHO
 9ZD7B/4nj0MZlzCQQDaBTKeZ+pE483Fs54t3lKiHBZlOYBnvaoG7FuJfxfVfXauKlHN4Hy/npdo
 C+bGJAHJxyKGX7wqRJN9HybGr9xeTy7MK7y+yXdifFP3w1hWy8IWWJIoWKsE7YHOBLKrZ1XfHhU
 iSDMnAbaBPrncZn2M8ZgcteoQUPCXfZpv8s5UfeNi+KncWpMN284N1our24zdgfTKg7UTI226+9
 5C8yM2dvlNaMR17hhohIeoKD5f0jtmiU65SOiyLtu2RkTSrXedIwOY2/Hp/fCPHPc2U2NyCxzR2
 6OmbqIoxFr1LqLmFQ490KkfbFmwXYWgYnZR9mpm8R2ex0Gbm
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kishon's TI email ID is not active anymore, so use his korg ID. Also, since
I've been maintaining the PCI endpoint framework, I'm willing to maintain
the DT binding as well. So add myself as the Co-maintainer.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 Documentation/devicetree/bindings/pci/pci-ep.yaml | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pci/pci-ep.yaml b/Documentation/devicetree/bindings/pci/pci-ep.yaml
index d1eef4825207..0b5456ee21eb 100644
--- a/Documentation/devicetree/bindings/pci/pci-ep.yaml
+++ b/Documentation/devicetree/bindings/pci/pci-ep.yaml
@@ -10,7 +10,8 @@ description: |
   Common properties for PCI Endpoint Controller Nodes.
 
 maintainers:
-  - Kishon Vijay Abraham I <kishon@ti.com>
+  - Kishon Vijay Abraham I <kishon@kernel.org>
+  - Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
 
 properties:
   $nodename:

-- 
2.25.1

