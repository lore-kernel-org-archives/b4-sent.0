From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 13:41:21 +0530
Subject: [PATCH v2 2/4] PCI: Indicate context lost if L1ss exit is broken
 during resume from system suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-l1ss-fix-v2-2-b2c3a4bdeb15@oss.qualcomm.com>
References: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
In-Reply-To: <20260519-l1ss-fix-v2-0-b2c3a4bdeb15@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Keith Busch <kbusch@kernel.org>, 
 Jens Axboe <axboe@kernel.dk>, Christoph Hellwig <hch@lst.de>, 
 Sagi Grimberg <sagi@grimberg.me>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-nvme@lists.infradead.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3331;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=i4F4KqDqI8ZgLEsx/6SfOqEOrYP4clWeClm6r9uw2Sw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDBsu9LB32B5u3ZCMkU0ywL6Z6k7E2oqPKkwRu
 TYsXoIlHFCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwbLgAKCRBVnxHm/pHO
 9ajKB/9hpUS2Zav/YkZSgcq7hl0iPI4PWX8Sk9I2fk3P2k64zuuVkojILMR+viEzxHyNSotRMOc
 0Txl2uQB8/Bo0qTbabhE/WuBwz61iAbuhfnY4jaTQ0ib8W6DIZ7pgZ4d7vQzfIFwNO+ooYB6Ppp
 U45/+ZkZVO7IrpdavoJ25W6nWOK/MFCaCCcPl2AstgWXl2br1kMAU52nXFlvEKmU6t9GOS53kKm
 Rng7b/dTbgpfXyBSX/Y/nWLzTDwkdMp6XfdCy1tlR8Ru8sIvKdfCm2xHLhqs/E90m+AYodybBNd
 vZPQHCcJQVWN/QP3V4uk8UH1PrPWtn9PxYgZm8fhhcs2jQbQ
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCIe spec v7.0, sec 5.5.3.3.1, states that for exiting L1.2 due to an
endpoint asserting CLKREQ# signal, the refclk must be turned on no earlier
than TL10_REFCLK_ON, and within the latency advertised in the LTR message.
This same behavior applies to L1.1 as well.

On some platforms like Qcom, these requirements are satisfied during OS
runtime, but not while resuming from the system suspend. This happens
because the PCIe RC driver may remove all resource votes and turns off the
analog circuitry of PHY during suspend to maximize power savings while
keeping the link in L1ss.

Consequently, when the endpoint asserts CLKREQ# to wake up, the OS must
first resume and the RC driver must restore the PHY and enable the REFCLK.
When this recovery process exceeds the L1ss exit latency time (roughly
L10_REFCLK_ON + T_COMMONMODE), the endpoint may treat it as a fatal
condition and triger Link Down (LDn). If the endpoint device is used to
host the RootFS, it will result in an OS crash. For other endpoints, it
may result in a complete device reset/recovery.

So to indicate this platform limitation to the client drivers, introduce a
new flag 'pci_host_bridge::broken_l1ss_resume' and check it in the
pci_suspend_retains_context() API. If the flag is set by the RC driver, the
API will return 'false' indicating the client drivers that the device
context may not be retained and the drivers must be prepared for context
loss.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pci.c   | 11 +++++++++++
 include/linux/pci.h |  2 ++
 2 files changed, 13 insertions(+)

diff --git a/drivers/pci/pci.c b/drivers/pci/pci.c
index 38cc5172d259..a7d2cb69b42e 100644
--- a/drivers/pci/pci.c
+++ b/drivers/pci/pci.c
@@ -2910,6 +2910,8 @@ void pci_config_pm_runtime_put(struct pci_dev *pdev)
  */
 bool pci_suspend_retains_context(struct pci_dev *pdev)
 {
+	struct pci_host_bridge *bridge = pci_find_host_bridge(pdev->bus);
+
 	/*
 	 * If the platform firmware (like ACPI) is involved at the end of system
 	 * suspend, device context may not be retained.
@@ -2917,6 +2919,15 @@ bool pci_suspend_retains_context(struct pci_dev *pdev)
 	if (pm_suspend_via_firmware())
 		return false;
 
+	/*
+	 * Some host bridges power off the PHY to enter deep low-power modes
+	 * during system suspend. Exiting L1 PM Substates from this condition
+	 * violates strict timing requirements and results in Link Down (LDn).
+	 * On such platforms, the endpoint must be prepared for context loss.
+	 */
+	if (bridge && bridge->broken_l1ss_resume)
+		return false;
+
 	/* Assume that the context is retained by default */
 	return true;
 }
diff --git a/include/linux/pci.h b/include/linux/pci.h
index f60f9e4e7b39..1e5b59fa258a 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -660,6 +660,8 @@ struct pci_host_bridge {
 	unsigned int	preserve_config:1;	/* Preserve FW resource setup */
 	unsigned int	size_windows:1;		/* Enable root bus sizing */
 	unsigned int	msi_domain:1;		/* Bridge wants MSI domain */
+	unsigned int	broken_l1ss_resume:1;	/* Resuming from L1ss during
+						   system suspend is broken */
 
 	/* Resource alignment requirements */
 	resource_size_t (*align_resource)(struct pci_dev *dev,

-- 
2.48.1

