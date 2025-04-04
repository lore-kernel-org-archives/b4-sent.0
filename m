From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 04 Apr 2025 13:52:22 +0530
Subject: [PATCH 2/4] PCI/ERR: Add support for resetting the slot in a
 platforms specific way
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250404-pcie-reset-slot-v1-2-98952918bf90@linaro.org>
References: <20250404-pcie-reset-slot-v1-0-98952918bf90@linaro.org>
In-Reply-To: <20250404-pcie-reset-slot-v1-0-98952918bf90@linaro.org>
To: Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>
Cc: dingwei@marvell.com, cassel@kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 linuxppc-dev@lists.ozlabs.org, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2254;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=J1pulK/QhUxJluY/dbX4w+yX5yzsNUDKLf1Z3h6Znak=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBn75bDRHEqWRk4266lWr88ralCgC34yIDiJDcQy
 8j9qOiUwGWJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ++WwwAKCRBVnxHm/pHO
 9Rq8B/9yjNScPcrhP4xoodQVe2UhQ06wX8j3FIiW/HCvPsWMdhDIXtFqRnnQJemw74T7Px8Rnpi
 c+ZVMPISLnO/A687KVnD3VDdzk9QBaViKfRPnVzVmTbudjSJWyHiR9EyLaAxH+hG26BSoSnbP1w
 aouo/8LRfXNRQlMdCh1CR7h6303yWBHTisq6wRfHyG/1lbuHN04IqZ7aflwaISj7dloF9c3uP7w
 o23Vh7HOHfwPK7JkrXyuY/H7xqBi77K63hN77hyDimtJiJhhR3sXumd5x0u+k2Z/YXwTuNXXnL1
 LEQ8T/VGLFZZ1a7uOZqhnslwXXjmxwachAAHMA+U3CJdFmjZ
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the PCI error handling requires resetting the slot, reset it using the
host bridge specific 'reset_slot' callback if available before calling the
'slot_reset' callback of the PCI drivers.

The 'reset_slot' callback is responsible for resetting the given slot
referenced by the 'pci_dev' pointer in a platform specific way and bring it
back to the working state if possible. If any error occurs during the slot
reset operation, relevant errno should be returned.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/pcie/err.c | 15 ++++++++++-----
 include/linux/pci.h    |  1 +
 2 files changed, 11 insertions(+), 5 deletions(-)

diff --git a/drivers/pci/pcie/err.c b/drivers/pci/pcie/err.c
index de6381c690f5c21f00021cdc7bde8d93a5c7db52..77ce9354532afee209f658175b86e625bba8a5ee 100644
--- a/drivers/pci/pcie/err.c
+++ b/drivers/pci/pcie/err.c
@@ -234,11 +234,16 @@ pci_ers_result_t pcie_do_recovery(struct pci_dev *dev,
 	}
 
 	if (status == PCI_ERS_RESULT_NEED_RESET) {
-		/*
-		 * TODO: Should call platform-specific
-		 * functions to reset slot before calling
-		 * drivers' slot_reset callbacks?
-		 */
+		if (host->reset_slot) {
+			ret = host->reset_slot(host, bridge);
+			if (ret) {
+				pci_err(bridge, "failed to reset slot: %d\n",
+					ret);
+				status = PCI_ERS_RESULT_DISCONNECT;
+				goto failed;
+			}
+		}
+
 		status = PCI_ERS_RESULT_RECOVERED;
 		pci_dbg(bridge, "broadcast slot_reset message\n");
 		pci_walk_bridge(bridge, report_slot_reset, &status);
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 0e8e3fd77e96713054388bdc82f439e51023c1bf..8d7d2a49b76cf64b4218b179cec495e0d69ddf6f 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -599,6 +599,7 @@ struct pci_host_bridge {
 	void (*release_fn)(struct pci_host_bridge *);
 	int (*enable_device)(struct pci_host_bridge *bridge, struct pci_dev *dev);
 	void (*disable_device)(struct pci_host_bridge *bridge, struct pci_dev *dev);
+	int (*reset_slot)(struct pci_host_bridge *bridge, struct pci_dev *dev);
 	void		*release_data;
 	unsigned int	ignore_reset_delay:1;	/* For entire hierarchy */
 	unsigned int	no_ext_tags:1;		/* No Extended Tags */

-- 
2.43.0

