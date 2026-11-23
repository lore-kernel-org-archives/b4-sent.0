From: Han Gao <gaohan@iscas.ac.cn>
Date: Tue, 24 Nov 2026 03:29:24 +0800
Subject: [PATCH] PCI: dwc: Split iATU windows at region limit boundaries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-dwc-iatu-boundary-v1-1-03c8e58514e1@iscas.ac.cn>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQqEMBBA4avI1Dtggqh4lWWLOBl1LKIkxh/Eu
 xvX8iveOyGwFw7QZCd4XiXI5BLUJwMajOsZxSaDznWplC7QboRilojtFJ01/kDSXFYV1aYmBam
 bPXey/5/f3+sQ25FpeUZwXTfl4h0hdQAAAA==
X-Change-ID: 20261124-dwc-iatu-boundary-c2e677c8a8c1
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Charles Mirabile <cmirabil@redhat.com>, 
 Randolph Lin <randolph@andestech.com>, Frank Li <Frank.Li@nxp.com>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-pci@vger.kernel.org, Han Gao <rabenda.cn@gmail.com>, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795462168; l=2144;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=LWq4t/W7/8Yh8qXqKLllSLq5ntvJqq5EalVbOE1tRmA=;
 b=ues/A1ukD7yttv0kwYfT+pgX19+/wfooG488bmDtAKIbV4ss0drz8BXLUvRxFBtBrd0wuawkF
 3+ex+aQO1QXCWXE3O33Y01xP/EKixtnNnzg6UTzm1OiLcEHy6n2tlxx
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dw_pcie_iatu_setup() splits a large window into region_limit + 1 sized
chunks starting at the window base. If the window doesn't start on a
region_limit boundary, the first chunk crosses one, the iATU programming
helpers reject it and the host fails to probe.

Stop each chunk at the next boundary instead. Inbound windows have the
same problem.

Fixes: e9a5415adb20 ("PCI: dwc: Use multiple iATU windows for mapping large bridge windows and DMA ranges")
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
I hit this on a Zhihe A210, where the config and I/O windows sit at the
start of a 4 GiB aligned aperture and the memory window follows them.
---
 drivers/pci/controller/dwc/pcie-designware-host.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index bbb02458af58..37f7a48bf4f6 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -952,7 +952,10 @@ static int dw_pcie_iatu_setup(struct dw_pcie_rp *pp)
 			}
 
 			atu.index = ob_iatu_index;
-			atu.size = MIN(pci->region_limit + 1, res_size);
+			/* Don't cross a region_limit boundary */
+			atu.size = MIN(pci->region_limit + 1 -
+				       (atu.parent_bus_addr & pci->region_limit),
+				       res_size);
 
 			ret = dw_pcie_prog_outbound_atu(pci, &atu);
 			if (ret) {
@@ -1030,7 +1033,11 @@ static int dw_pcie_iatu_setup(struct dw_pcie_rp *pp)
 				return -ENOMEM;
 			}
 
-			window_size = MIN(pci->region_limit + 1, res_size);
+			/* Don't cross a region_limit boundary */
+			window_size = MIN(pci->region_limit + 1 -
+					  ((res_start - entry->offset) &
+					   pci->region_limit),
+					  res_size);
 			ret = dw_pcie_prog_inbound_atu(pci, ib_iatu_index,
 						       PCIE_TLP_TYPE_MEM_RDWR, res_start,
 						       res_start - entry->offset, window_size);

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261124-dwc-iatu-boundary-c2e677c8a8c1

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

