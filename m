From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 16 Apr 2025 21:59:05 +0530
Subject: [PATCH v2 3/4] PCI: Add link down handling for host bridges
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-pcie-reset-slot-v2-3-efe76b278c10@linaro.org>
References: <20250416-pcie-reset-slot-v2-0-efe76b278c10@linaro.org>
In-Reply-To: <20250416-pcie-reset-slot-v2-0-efe76b278c10@linaro.org>
To: Mahesh J Salgaonkar <mahesh@linux.ibm.com>, 
 Oliver O'Halloran <oohall@gmail.com>, Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>
Cc: dingwei@marvell.com, cassel@kernel.org, Lukas Wunner <lukas@wunner.de>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 linuxppc-dev@lists.ozlabs.org, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5199;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=lEJMTheXv7TkxX7FcSXxWDHTdFlcl4i5pVx1YeWN9fA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBn/9rXxS8C/6Fb1mSogflJ2GvH10SSe2Bg+GkU9
 4/sP5k6EA2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ//a1wAKCRBVnxHm/pHO
 9deGB/0SC83yXRK8fZirz8yjVN0ZOkIq2gfWTRyPBDR3lbS/TtJ7RN2RdTMGJZWi2QmsH9dlpkc
 eGKL1tllmLi60EyApZlpGqXksaN7OpGLI2pTxoCveILLrzdVhVP4795rU+xuqXwtd7TOGVy9Pey
 rH4aPWbus6UWsax1CaUClmo+wnmK73R67QIiv/o/Rz/BDXSh6JZ+asx02rDLBN7Wb4JbMvlR8Of
 sGxktWntkan/7siYofP9FbPU2Bplq+0PNyFNJQrh8CYCs2BvESumMUzJerDqcY++II0w9k6ZndP
 XGE3WzHMxek22XMzPv+Xh1KIiXBtWVrtZcu8CDBZtoNXnziP
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCI link, when down, needs to be recovered to bring it back. But that
cannot be done in a generic way as link recovery procedure is specific to
host bridges. So add a new API pci_host_handle_link_down() that could be
called by the host bridge drivers when the link goes down.

The API will iterate through all the slots and calls the pcie_do_recovery()
function with 'pci_channel_io_frozen' as the state. This will result in the
execution of the AER Fatal error handling code. Since the link down
recovery is pretty much the same as AER Fatal error handling,
pcie_do_recovery() helper is reused here. First the AER error_detected
callback will be triggered for the bridge and the downstream devices. Then,
pcie_do_slot_reset() will be called for each slots, which will reset the
slots using 'reset_slot' callback to recover the link. Once that's done,
resume message will be broadcasted to the bridge and the downstream devices
indicating successful link recovery.

In case if the AER support is not enabled in the kernel, only
pci_bus_error_reset() will be called for each slots as there is no way we
could inform the drivers about link recovery.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/pci.h      | 21 +++++++++++++++++++++
 drivers/pci/pcie/err.c | 27 +++++++++++++++++++++++++++
 drivers/pci/probe.c    |  7 +++++++
 include/linux/pci.h    |  1 +
 4 files changed, 56 insertions(+)

diff --git a/drivers/pci/pci.h b/drivers/pci/pci.h
index b81e99cd4b62a3022c8b07a09f212f6888674487..6c1d4c5a82d68e5842636ff296a8d3a06487cb11 100644
--- a/drivers/pci/pci.h
+++ b/drivers/pci/pci.h
@@ -966,6 +966,7 @@ int pci_aer_clear_status(struct pci_dev *dev);
 int pci_aer_raw_clear_status(struct pci_dev *dev);
 void pci_save_aer_state(struct pci_dev *dev);
 void pci_restore_aer_state(struct pci_dev *dev);
+void pcie_do_recover_slots(struct pci_host_bridge *host);
 #else
 static inline void pci_no_aer(void) { }
 static inline void pci_aer_init(struct pci_dev *d) { }
@@ -975,6 +976,26 @@ static inline int pci_aer_clear_status(struct pci_dev *dev) { return -EINVAL; }
 static inline int pci_aer_raw_clear_status(struct pci_dev *dev) { return -EINVAL; }
 static inline void pci_save_aer_state(struct pci_dev *dev) { }
 static inline void pci_restore_aer_state(struct pci_dev *dev) { }
+static inline void pcie_do_recover_slots(struct pci_host_bridge *host)
+{
+	struct pci_bus *bus = host->bus;
+	struct pci_dev *dev;
+	int ret;
+
+	if (!host->reset_slot)
+		dev_warn(&host->dev, "Missing reset_slot() callback\n");
+
+	for_each_pci_bridge(dev, bus) {
+		if (!pci_is_root_bus(bus))
+			continue;
+
+		ret = pci_bus_error_reset(dev);
+		if (ret)
+			pci_err(dev, "Failed to reset slot: %d\n", ret);
+		else
+			pci_info(dev, "Slot has been reset\n");
+	}
+}
 #endif
 
 #ifdef CONFIG_ACPI
diff --git a/drivers/pci/pcie/err.c b/drivers/pci/pcie/err.c
index b834fc0d705938540d3d7d3d8739770c09fe7cf1..70d8cd37255c5638fddf38e13ea87cb8ebe8553f 100644
--- a/drivers/pci/pcie/err.c
+++ b/drivers/pci/pcie/err.c
@@ -270,3 +270,30 @@ pci_ers_result_t pcie_do_recovery(struct pci_dev *dev,
 
 	return status;
 }
+
+static pci_ers_result_t pcie_do_slot_reset(struct pci_dev *dev)
+{
+	int ret;
+
+	ret = pci_bus_error_reset(dev);
+	if (ret) {
+		pci_err(dev, "Failed to reset slot: %d\n", ret);
+		return PCI_ERS_RESULT_DISCONNECT;
+	}
+
+	pci_info(dev, "Slot has been reset\n");
+
+	return PCI_ERS_RESULT_RECOVERED;
+}
+
+void pcie_do_recover_slots(struct pci_host_bridge *host)
+{
+	struct pci_bus *bus = host->bus;
+	struct pci_dev *dev;
+
+	for_each_pci_bridge(dev, bus) {
+		if (pci_is_root_bus(bus))
+			pcie_do_recovery(dev, pci_channel_io_frozen,
+					 pcie_do_slot_reset);
+	}
+}
diff --git a/drivers/pci/probe.c b/drivers/pci/probe.c
index 364fa2a514f8a68fb18bded3259c6847d3932f8b..60ad20eea0259797e68afa7979bb1fc24b6f213b 100644
--- a/drivers/pci/probe.c
+++ b/drivers/pci/probe.c
@@ -3249,6 +3249,13 @@ int pci_host_probe(struct pci_host_bridge *bridge)
 }
 EXPORT_SYMBOL_GPL(pci_host_probe);
 
+void pci_host_handle_link_down(struct pci_host_bridge *bridge)
+{
+	dev_info(&bridge->dev, "Recovering slots due to Link Down\n");
+	pcie_do_recover_slots(bridge);
+}
+EXPORT_SYMBOL_GPL(pci_host_handle_link_down);
+
 int pci_bus_insert_busn_res(struct pci_bus *b, int bus, int bus_max)
 {
 	struct resource *res = &b->busn_res;
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 8d7d2a49b76cf64b4218b179cec495e0d69ddf6f..76e977af2d524200b67f39a6d0417ee565cf5116 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -1157,6 +1157,7 @@ struct pci_bus *pci_create_root_bus(struct device *parent, int bus,
 				    struct pci_ops *ops, void *sysdata,
 				    struct list_head *resources);
 int pci_host_probe(struct pci_host_bridge *bridge);
+void pci_host_handle_link_down(struct pci_host_bridge *bridge);
 int pci_bus_insert_busn_res(struct pci_bus *b, int bus, int busmax);
 int pci_bus_update_busn_res_end(struct pci_bus *b, int busmax);
 void pci_bus_release_busn_res(struct pci_bus *b);

-- 
2.43.0

