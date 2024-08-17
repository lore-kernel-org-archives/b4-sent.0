From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Sat, 17 Aug 2024 11:09:04 +0530
Subject: [PATCH 2/2] PCI: tegra194: Move controller cleanups to
 pex_ep_event_pex_rst_deassert()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240817-pci-qcom-ep-cleanup-v1-2-d6b958226559@linaro.org>
References: <20240817-pci-qcom-ep-cleanup-v1-0-d6b958226559@linaro.org>
In-Reply-To: <20240817-pci-qcom-ep-cleanup-v1-0-d6b958226559@linaro.org>
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Vidya Sagar <vidyas@nvidia.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Thierry Reding <treding@nvidia.com>, 
 linux-tegra@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3042;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Gpj3bCNv2Ngi3Fb+SdoC72OTyVZAosVFWqztoxn1DI8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmwDd5+Q7Oy8V76rsxPlmGh9rN2LDwu2fT+RggS
 mu4/0p+zU+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZsA3eQAKCRBVnxHm/pHO
 9eKtB/4yI6toXqLRwhcYnBU0Fz5V1xWq8znAlFXkOW1w0/R+REcaQl1E8eO1HhYb2HBc5qEo75d
 lpNmdahVggWI+2fF1fPc1iPj8wUZWWqBjIUa0/WNt4AE1X7nTcH+k5K5JdIAjco3xKGGcxW6rLr
 2GLILxw583kWRMP6eKd/hWuM/sR0Rb8oEkXjZqEN+7kjBxKb3cI+SqwyDIi9y1Wl+B3zPXuY4Cg
 xmPh0Kb50qkt+ZTgnVHKBhijZD8fQQ88UR8Nq9nHl7zFGga2VLDWdqjMQWaeWzLIoAa1XFThAeS
 NWDaRBIWpD/IvNTy4E9hlLMf4akRCjZWh7t2UFoq0bDwZu0w
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the endpoint cleanup function dw_pcie_ep_cleanup() and EPF
deinit notify function pci_epc_deinit_notify() are called during the
execution of pex_ep_event_pex_rst_assert() i.e., when the host has asserted
PERST#. But quickly after this step, refclk will also be disabled by the
host.

All of the tegra194 endpoint SoCs supported as of now depend on the refclk
from the host for keeping the controller operational. Due to this
limitation, any access to the hardware registers in the absence of refclk
will result in a whole endpoint crash. Unfortunately, most of the
controller cleanups require accessing the hardware registers (like eDMA
cleanup performed in dw_pcie_ep_cleanup(), etc...). So these cleanup
functions can cause the crash in the endpoint SoC once host asserts PERST#.

One way to address this issue is by generating the refclk in the endpoint
itself and not depending on the host. But that is not always possible as
some of the endpoint designs do require the endpoint to consume refclk from
the host.

So let's fix this crash by moving the controller cleanups to the start of
the pex_ep_event_pex_rst_deassert() function. This function is called
whenever the host has deasserted PERST# and it is guaranteed that the
refclk would be active at this point. So at the start of this function
(after enabling resources) the controller cleanup can be performed. Once
finished, rest of the code execution for PERST# deassert can continue as
usual.

Cc: Thierry Reding <thierry.reding@gmail.com>
Cc: Jonathan Hunter <jonathanh@nvidia.com>
Cc: Vidya Sagar <vidyas@nvidia.com>
Cc: linux-tegra@vger.kernel.org
Fixes: 473b2cf9c4d1 ("PCI: endpoint: Introduce 'epc_deinit' event and notify the EPF drivers")
Fixes: 570d7715eed8 ("PCI: dwc: ep: Introduce dw_pcie_ep_cleanup() API for drivers supporting PERST#")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-tegra194.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-tegra194.c b/drivers/pci/controller/dwc/pcie-tegra194.c
index 4bf7b433417a..d68dd18ed43c 100644
--- a/drivers/pci/controller/dwc/pcie-tegra194.c
+++ b/drivers/pci/controller/dwc/pcie-tegra194.c
@@ -1709,9 +1709,6 @@ static void pex_ep_event_pex_rst_assert(struct tegra_pcie_dw *pcie)
 	if (ret)
 		dev_err(pcie->dev, "Failed to go Detect state: %d\n", ret);
 
-	pci_epc_deinit_notify(pcie->pci.ep.epc);
-	dw_pcie_ep_cleanup(&pcie->pci.ep);
-
 	reset_control_assert(pcie->core_rst);
 
 	tegra_pcie_disable_phy(pcie);
@@ -1790,6 +1787,10 @@ static void pex_ep_event_pex_rst_deassert(struct tegra_pcie_dw *pcie)
 		goto fail_phy;
 	}
 
+	/* Perform cleanup that requires refclk */
+	pci_epc_deinit_notify(pcie->pci.ep.epc);
+	dw_pcie_ep_cleanup(&pcie->pci.ep);
+
 	/* Clear any stale interrupt statuses */
 	appl_writel(pcie, 0xFFFFFFFF, APPL_INTR_STATUS_L0);
 	appl_writel(pcie, 0xFFFFFFFF, APPL_INTR_STATUS_L1_0_0);

-- 
2.25.1

