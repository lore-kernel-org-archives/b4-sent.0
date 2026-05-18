From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 18 May 2026 20:29:13 +0530
Subject: [PATCH v8 1/5] PCI: dwc: ep: Clear MSI iATU mapping in
 dw_pcie_ep_cleanup()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-pci-port-reset-v8-1-eb5a7d331dfc@oss.qualcomm.com>
References: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
In-Reply-To: <20260518-pci-port-reset-v8-0-eb5a7d331dfc@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Will Deacon <will@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 Niklas Cassel <cassel@kernel.org>, 
 Wilfred Mallawa <wilfred.mallawa@wdc.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 mani@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Richard Zhu <hongxing.zhu@nxp.com>, Brian Norris <briannorris@chromium.org>, 
 Wilson Ding <dingwei@marvell.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1818;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=DOBc0qbyq7keowKanldmTADeubkY3d2RuxJiiS/OOM4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCylUbgmSbz1kVr7omfIK0go80pJFvGDFzpmhY
 9nEuMnSMXmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagspVAAKCRBVnxHm/pHO
 9Vp1B/wOqPF1w4/rxr1pZQAJ04G+p0MJoPG4wsGqn4QByaQH0A6xK3NTFRxmhprieh8pAZUVLiv
 Bfk9nqjL34e6h89veBGMpdtMjzM5K1Yd9rjfahszPgaQnTozmKX71C3zG2Gf62yCYbGIxDU0fN7
 wF9y8NDGQ6mY1osHaoCK76W0XZIqiR1qUOwlVUh1xNCspSycCzJc5KhSmcBZdrc+PrEP9ukFuQv
 W/NyAxeQV/Sz0vX+7XKAac8Blfb/ubk0kqlWq+KbLJaIh1DUw/sp7UVCIx3SVbGMVcDmGjrBopn
 /XHtcZL3biY8r5MXhNm5m2XnDXLSZk3RcxLpbHTE5Q5nhg/6
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MSI iATU mapping is currently only cleared when the endpoint is
stopped via configfs or when the host updates the MSI address/size.
This avoids redundant iATU reconfiguration every time the endpoint
raises an MSI interrupt.

However, a fundamental reset triggered by PERST# assert/deassert
resets all iATU inbound/outbound registers without going through the
configfs stop path. If the host also retains the same MSI address/size
after PERST# deassert, the driver never clears the stale MSI iATU
mapping. It then continues using this stale mapping to raise the MSI
interrupts, which can cause IOMMU faults and MSI failures on the host.

Fix this by clearing the MSI iATU mapping inside dw_pcie_ep_cleanup(),
which is already called as part of the PERST# assert/deassert sequence.
This unmaps the MSI iATU region and sets the msi_iatu_mapped flag to
false, ensuring that dw_pcie_ep_raise_msi_irq() performs a fresh iATU
mapping on its next invocation, regardless of whether the host changed
the MSI address/size.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-ep.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/pci/controller/dwc/pcie-designware-ep.c b/drivers/pci/controller/dwc/pcie-designware-ep.c
index d4dc3b24da60..4ae0e1b55f39 100644
--- a/drivers/pci/controller/dwc/pcie-designware-ep.c
+++ b/drivers/pci/controller/dwc/pcie-designware-ep.c
@@ -1035,6 +1035,11 @@ void dw_pcie_ep_cleanup(struct dw_pcie_ep *ep)
 {
 	struct dw_pcie *pci = to_dw_pcie_from_ep(ep);
 
+	if (ep->msi_iatu_mapped) {
+		dw_pcie_ep_unmap_addr(ep->epc, 0, 0, ep->msi_mem_phys);
+		ep->msi_iatu_mapped = false;
+	}
+
 	dwc_pcie_debugfs_deinit(pci);
 	dw_pcie_edma_remove(pci);
 }

-- 
2.48.1

