From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 31 Jul 2024 16:20:05 +0530
Subject: [PATCH v3 02/13] PCI: qcom-ep: Reword the error message for
 receiving unknown global IRQ event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240731-pci-qcom-hotplug-v3-2-a1426afdee3b@linaro.org>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=1256;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=B8RUdvVv9QEg4h2fDtSWIh3luhRVOKTDULQMHpO/Rk0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmqhbiPvlBYFkyQTm0FUkbIjHMH/+/ZAg11HCjV
 xz5OPlMCDyJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqoW4gAKCRBVnxHm/pHO
 9fAkB/9WOZ4Pm2vf1vP5hHdw6Ggj3kP1To3Upq1DZPNUvBuxAfX3SX7dC3Ec1cwU48Ig/RWN8fR
 4mB7xUJOFQa+XKdRaAp4nH/I39Pfnze4V4UZuoPuTMvZ6186dX4gm3alkr3ElT1RbwkKXLmUfMt
 Ml7vht4ZW7OgGLMCWTsNQDRUaddRLqmlrmyhniidJYOYFV/mzfO8HSXDkgwLh23sgVmLoqQ+zWI
 5ttBWDYgVU55MHsvjIbhRaG3VJaSRo3CtuxjytmhZu5yJ7EoSDLBQSPzQNVXsPOcj0jLcqVD9uJ
 2XmiqdsNSDOyUwy8/85yTfrnuvIoN1yGMptRMN+npS3NWfdc
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

