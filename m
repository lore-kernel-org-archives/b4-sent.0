From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 28 Aug 2024 21:16:12 +0530
Subject: [PATCH v4 02/12] PCI: qcom-ep: Reword the error message for
 receiving unknown global IRQ event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240828-pci-qcom-hotplug-v4-2-263a385fbbcb@linaro.org>
References: <20240828-pci-qcom-hotplug-v4-0-263a385fbbcb@linaro.org>
In-Reply-To: <20240828-pci-qcom-hotplug-v4-0-263a385fbbcb@linaro.org>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1256;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=B8RUdvVv9QEg4h2fDtSWIh3luhRVOKTDULQMHpO/Rk0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmz0ZLNt9QNPKv9NKAKbZ5eVVEDlJxVPTsCl4yZ
 H4jVagxg8KJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZs9GSwAKCRBVnxHm/pHO
 9cEpB/4hP+YKCmtIoOu2Hobc2nRJn8ozN5UY9byuFg1YQ5A1UEpxS1qIj/AsDmQdV9VTq5uHzGM
 328jQY5jYgixBeIhqP4j1hMIWYRj1u/IsKn0n+dIuIU3dG6LE/YZ7nEKXToBSR72kQDRqO59alz
 WzXQTeR8g87j1LgD4ZjW61UaFEEWMFrDZFHezITn8NV9Oy0lbwJRaV7QDzlVgpuIWPkP2a7Kzhl
 dc2+VD7cLBgch/22b8vPvycHUyVl+UzorHJhFDRkSBx8eu7jpX78UD738y9xO7ESP5/Z9JwJNKC
 ucR+cweFjvWOdffPpzPYLz3GBumFwjJcJEGsVOy2gwP8c/UG
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current error message just prints the contents of PARF_INT_ALL_STATUS
register as if like the IRQ event number. It could mislead the users.
Reword it to make it clear that the error message is actually showing the
interrupt status register to help debug spurious IRQ events.

While at it, let's also switch over to dev_WARN_ONCE() so that any IRQ
storm won't flood the kernel log buffer.

Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-qcom-ep.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom-ep.c b/drivers/pci/controller/dwc/pcie-qcom-ep.c
index 972a90eba494..0bb0a056dd8f 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-ep.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-ep.c
@@ -679,7 +679,8 @@ static irqreturn_t qcom_pcie_ep_global_irq_thread(int irq, void *data)
 		dw_pcie_ep_linkup(&pci->ep);
 		pcie_ep->link_status = QCOM_PCIE_EP_LINK_UP;
 	} else {
-		dev_err(dev, "Received unknown event: %d\n", status);
+		dev_WARN_ONCE(dev, 1, "Received unknown event. INT_STATUS: 0x%08x\n",
+			      status);
 	}
 
 	return IRQ_HANDLED;

-- 
2.25.1

