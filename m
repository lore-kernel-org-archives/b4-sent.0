From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 15 Jul 2024 23:03:44 +0530
Subject: [PATCH 02/14] PCI: qcom-ep: Reword the error message for receiving
 unknown global IRQ event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240715-pci-qcom-hotplug-v1-2-5f3765cc873a@linaro.org>
References: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
In-Reply-To: <20240715-pci-qcom-hotplug-v1-0-5f3765cc873a@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=1070;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=JCsYTkuXXXhcuENPNzaZvR8u/dChlzvKuuKaF9P+7zw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmlV14QVjURbmKvogp/beRq+rrFjLZw7fylgAgA
 objhy0MyT2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZpVdeAAKCRBVnxHm/pHO
 9XK4B/4trxc4KZfujiglm6c9LAzE6vUPsdr2rj/6hxTB844v6joCV7FZ97V+u4oqXWExMK1iFFR
 d4tWeUCRMfZfFEIEnyeEuSljW+e4elQZt7zpLT1gv7AFiukySJXrgyvbRwV/7rPxX1AAlhuwcUV
 epUijoRNuGLtSECo4A6j2wu8scZUpZWLssd0krrix7SIqqhIVFunPEdnjhI18+dTlNtot6Kb6CP
 I9k0VgZjGuFBEfWAa1BxKVTo1hNy/DIOBRNumFEhK6CiZGyHYuiGNbx2LIEbiyPR2lyXz933Le6
 uPIP+1QAhPwBGrPtDqvYpkJE6WKzHwv23olwzn1KgAXJTTpi
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Current error message just prints the contents of PARF_INT_ALL_STATUS
register as if like the IRQ event number. It could mislead the users.
Reword it to make it clear that the error message is actually showing the
interrupt status register to help debug spurious IRQ events.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-qcom-ep.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom-ep.c b/drivers/pci/controller/dwc/pcie-qcom-ep.c
index 972a90eba494..cda5d8fdc03b 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-ep.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-ep.c
@@ -679,7 +679,8 @@ static irqreturn_t qcom_pcie_ep_global_irq_thread(int irq, void *data)
 		dw_pcie_ep_linkup(&pci->ep);
 		pcie_ep->link_status = QCOM_PCIE_EP_LINK_UP;
 	} else {
-		dev_err(dev, "Received unknown event: %d\n", status);
+		dev_err(dev, "Received unknown event. INT_STATUS: 0x%08x\n",
+			status);
 	}
 
 	return IRQ_HANDLED;

-- 
2.25.1

