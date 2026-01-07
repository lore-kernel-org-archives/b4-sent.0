From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 07 Jan 2026 13:41:57 +0530
Subject: [PATCH v4 4/6] PCI: dwc: Only skip the dw_pcie_wait_for_link()
 failure if it returns -ENODEV
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pci-dwc-suspend-rework-v4-4-9b5f3c72df0a@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1204;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=CClkmOJOF6jdGk3GCx6uryCHLsqrAzBQPUqzwqi9zYU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpXhVOGmRP2AlbYJACIPOBXvP1+/o5cQd7NabzK
 z/MLTmp+ROJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaV4VTgAKCRBVnxHm/pHO
 9UtFCACEtjoJo3LIhw+8whZppEXDWvFUJgzWrjFas8UhhcWf7Ra4CCWrNMBN6Vmp212C9RHtYkQ
 s/Tmskd2ukLK6xrFr+NM/y08MhV1Py5fUz5T2jY279wm3fXhnVFUQtK3p+y8K+Y5uOEmV33qS3m
 CJ5Ro2r6QWkfWq/6Xc0GvLp3rX8YwuKEmGgvJxX93Qdtpkj/gd98wGeMjBDyxTJIIiNhHlOoObZ
 hIAa+kq3R3V0BhkMqIAImUKK1PD5Ro0FOqlCiYRNlCFHRYk2M+XgxXNrfUd0DSA1VG3C0KaqUlp
 Nz3wuVzqevSWFHcoOU7qegpmU7AaAlrqwmGGQi3yhKVaxbqY
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dw_pcie_wait_for_link() now returns -ENODEV if the device is not found on
the bus and -ETIMEDOUT if the link fails to come up for any other reasons.
And it is incorrect to skip the link up failures other than device not
found. So only skip the failure for device not found case and handle
failure for other reasons.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware-host.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware-host.c b/drivers/pci/controller/dwc/pcie-designware-host.c
index fad0cbedefbc..ccde12b85463 100644
--- a/drivers/pci/controller/dwc/pcie-designware-host.c
+++ b/drivers/pci/controller/dwc/pcie-designware-host.c
@@ -675,8 +675,10 @@ int dw_pcie_host_init(struct dw_pcie_rp *pp)
 			goto err_remove_edma;
 	}
 
-	/* Ignore errors, the link may come up later */
-	dw_pcie_wait_for_link(pci);
+	/* Skip failure if the device is not found as it may show up later */
+	ret = dw_pcie_wait_for_link(pci);
+	if (ret && ret != -ENODEV)
+		goto err_stop_link;
 
 	ret = pci_host_probe(bridge);
 	if (ret)

-- 
2.48.1

