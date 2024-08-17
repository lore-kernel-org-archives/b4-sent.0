From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Sat, 17 Aug 2024 11:09:03 +0530
Subject: [PATCH 1/2] PCI: qcom-ep: Move controller cleanups to
 qcom_pcie_perst_deassert()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240817-pci-qcom-ep-cleanup-v1-1-d6b958226559@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2892;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=nvYCXsJUQRNDkqxK/5DBlZ4jMTQnZ2mxPzwj87Woaa0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmwDd5ePjMmYbGHoJRMqAkEyHBuWUKDeDATP5+w
 WMHgGtevCiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZsA3eQAKCRBVnxHm/pHO
 9VOpB/91/N2nyY5n8uTAftgnS5juJq4oggVmjQnDI7XsNORmjlPDF1LLdGkbQc6QHqmfzVfgK7d
 JwBIW3vZ6eWm38vHFHTRmqgMieA6jOvjtIduaxVFm3PxWv0tieA9vR38EUyZ5qv7kSPZGcbopFK
 oVtiXHA8Kn0dl7zlwnPWgyk6AoKmuUaQJYL3jD67d5pJYFJ68SdHEQEOpCZH4GkeYG2cscEH9a2
 0StE0TzFf/8dIfynpqqANOz9U5aBCncRZyUCrRUxUjgW+iYIxgxv8vbsHb3OB8NZtpa+crsDEIH
 Ik5Wmxww9YynsitHpa3IUXiD9/Q3/EkWszY58pz7zXpQWxF1
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the endpoint cleanup function dw_pcie_ep_cleanup() and EPF
deinit notify function pci_epc_deinit_notify() are called during the
execution of qcom_pcie_perst_assert() i.e., when the host has asserted
PERST#. But quickly after this step, refclk will also be disabled by the
host.

All of the Qcom endpoint SoCs supported as of now depend on the refclk from
the host for keeping the controller operational. Due to this limitation,
any access to the hardware registers in the absence of refclk will result
in a whole endpoint crash. Unfortunately, most of the controller cleanups
require accessing the hardware registers (like eDMA cleanup performed in
dw_pcie_ep_cleanup(), powering down MHI EPF etc...). So these cleanup
functions are currently causing the crash in the endpoint SoC once host
asserts PERST#.

One way to address this issue is by generating the refclk in the endpoint
itself and not depending on the host. But that is not always possible as
some of the endpoint designs do require the endpoint to consume refclk from
the host (as I was told by the Qcom engineers).

So let's fix this crash by moving the controller cleanups to the start of
the qcom_pcie_perst_deassert() function. qcom_pcie_perst_deassert() is
called whenever the host has deasserted PERST# and it is guaranteed that
the refclk would be active at this point. So at the start of this function
(after enabling resources), the controller cleanup can be performed. Once
finished, rest of the code execution for PERST# deassert can continue as
usual.

Fixes: 473b2cf9c4d1 ("PCI: endpoint: Introduce 'epc_deinit' event and notify the EPF drivers")
Fixes: 570d7715eed8 ("PCI: dwc: ep: Introduce dw_pcie_ep_cleanup() API for drivers supporting PERST#")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-qcom-ep.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-qcom-ep.c b/drivers/pci/controller/dwc/pcie-qcom-ep.c
index 236229f66c80..5d31285685b6 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-ep.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-ep.c
@@ -389,6 +389,10 @@ static int qcom_pcie_perst_deassert(struct dw_pcie *pci)
 		return ret;
 	}
 
+	/* Perform cleanup that requires refclk */
+	pci_epc_deinit_notify(pci->ep.epc);
+	dw_pcie_ep_cleanup(&pci->ep);
+
 	/* Assert WAKE# to RC to indicate device is ready */
 	gpiod_set_value_cansleep(pcie_ep->wake, 1);
 	usleep_range(WAKE_DELAY_US, WAKE_DELAY_US + 500);
@@ -522,8 +526,6 @@ static void qcom_pcie_perst_assert(struct dw_pcie *pci)
 {
 	struct qcom_pcie_ep *pcie_ep = to_pcie_ep(pci);
 
-	pci_epc_deinit_notify(pci->ep.epc);
-	dw_pcie_ep_cleanup(&pci->ep);
 	qcom_pcie_disable_resources(pcie_ep);
 	pcie_ep->link_status = QCOM_PCIE_EP_LINK_DISABLED;
 }

-- 
2.25.1

