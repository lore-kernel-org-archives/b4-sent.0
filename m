From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 07 Jan 2026 13:41:56 +0530
Subject: [PATCH v4 3/6] PCI: dwc: Rework the error print of
 dw_pcie_wait_for_link()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pci-dwc-suspend-rework-v4-3-9b5f3c72df0a@oss.qualcomm.com>
References: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
In-Reply-To: <20260107-pci-dwc-suspend-rework-v4-0-9b5f3c72df0a@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1068;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=7kXiC+5h1EOCvJw9bEDf4bWdlgkGwkMaGfwFegH0XMU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXhVO+wv6IqrXUHtZZ7pCoWCmyGAxjzy7H7TCb
 gQK13gxUTCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV4VTgAKCRBVnxHm/pHO
 9U2KB/4m72B41t7n/mvH/degieIy7YePSsqP5IBleoaDzPOABR/ntbxCFhi9USstVjCjposC/1Y
 PeBT1LFHVwCe+ZI4a8ZQD8yBGdRVxcUdItAYYUvUuIa78PjPSHy7dJdqhYYqeb45E/812waSWOC
 e44WBUt4/UP8XNNN35fyk8QOoIz3lLo9o6+Ie9zXy2FX3I8tXNY3kb2yxdByomr4HLoQHvJHYqs
 CtZNrWzpvpdW9DmYjd9rLlDbBXVSW4qU8dbqWSxO8G8wFYgO/Kh6R8rNOjFKQMHQ1kWRYlnF8TI
 yvqeok1ufUpEnVSfef6J7BRzeqK9Tko1x1PFTa6hnrQdzeBa
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the link fails to come up even after detecting the device on the bus
i.e., if the LTSSM is not in Detect.Quiet and Detect.Active states, then
dw_pcie_wait_for_link() should log it as an error.

So promote dev_info() to dev_err(), reword the error log to make it clear
and also print the LTSSM state to aid debugging.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 87f2ebc134d6..c2dfadc53d04 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -776,7 +776,8 @@ int dw_pcie_wait_for_link(struct dw_pcie *pci)
 			return -ENODEV;
 		}
 
-		dev_info(pci->dev, "Phy link never came up\n");
+		dev_err(pci->dev, "Link failed to come up. LTSSM: %s\n",
+			dw_pcie_ltssm_status_string(ltssm));
 		return -ETIMEDOUT;
 	}
 

-- 
2.48.1

