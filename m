From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 14 Apr 2026 21:29:40 +0530
Subject: [PATCH 2/4] PCI: Indicate context lost if L1ss exit is broken
 during resume from system suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-l1ss-fix-v1-2-adbb4555b5ab@oss.qualcomm.com>
References: <20260414-l1ss-fix-v1-0-adbb4555b5ab@oss.qualcomm.com>
In-Reply-To: <20260414-l1ss-fix-v1-0-adbb4555b5ab@oss.qualcomm.com>
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
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3305;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=LyQjngZpjyM7atFii62PC/2oWcdYdOsG7s31euB1g4g=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp3mSJmlZhEN3RfjDf/GEGFtsvDX0Ll8oF+/ind
 omQnGB3tZqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCad5kiQAKCRBVnxHm/pHO
 9ZQPB/0TFauDo1bNl4OhfXKRCke7aoRExVdAT6cGff+51gC9NlEDUehXTYuzKL5aDTHYH3ze3Ev
 ff8UzBeyFVUlIkHbaYlWYXMsWfgsT9c+cFuKXMqflurzV6GJZWp6wfJGoEl91gbonS6TDmLwITa
 Auq6bnsaVRZULioqu2rI37EFXRDXcAZLL6CGooAg7SHcTBHs+08DXbUHuneegTd82hf+KOD81uY
 CoGr1SLR5WAn4VwxhvlFNQTPH5oPDwNj9kbNQrNtT/tLV1wUrSNbhtArNOVdkPJDGtFuRx35Muz
 OoYeVIpwIXc6uVTS5uNg88zL70+ulUzFTKjvoG118XKUHMag
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
PHY during suspend to maximize power savings while keeping the link in
L1ss.

Consequently, when the endpoint asserts CLKREQ# to wake up, the OS must
first resume and the RC driver must restore the PHY and enable the refclk.
This recovery process exceeds the L1ss exit latency time. And this latency
violation results in an L1ss exit timeout, followed by Link Down (LDn). If
the endpoint device is used to host the RootFS, it will result in an OS
crash. For other endpoints, it may result in a complete device
reset/recovery.

So to indicate this platform limitation to the client drivers, introduce a
new flag 'pci_host_bridge::broken_l1ss_resume' and check it in the
pci_dev_suspend_retention_supported() API. If the flag is set by the RC
driver, the API will return 'false' indicating the client drivers that the
device context may not be retained and the drivers must be prepared for
context loss.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pci.c   | 11 +++++++++++
 include/linux/pci.h |  2 ++
 2 files changed, 13 insertions(+)

diff --git a/drivers/pci/pci.c b/drivers/pci/pci.c
index 211616467a77..e871cccf24ae 100644
--- a/drivers/pci/pci.c
+++ b/drivers/pci/pci.c
@@ -2911,6 +2911,8 @@ void pci_config_pm_runtime_put(struct pci_dev *pdev)
  */
 bool pci_dev_suspend_retention_supported(struct pci_dev *pdev)
 {
+	struct pci_host_bridge *bridge = pci_find_host_bridge(pdev->bus);
+
 	/*
 	 * If the platform firmware (like ACPI) is involved at the end of system
 	 * suspend, device context may not be retained.
@@ -2918,6 +2920,15 @@ bool pci_dev_suspend_retention_supported(struct pci_dev *pdev)
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
index d9bc7ad4eaa4..860d8a774b51 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -658,6 +658,8 @@ struct pci_host_bridge {
 	unsigned int	preserve_config:1;	/* Preserve FW resource setup */
 	unsigned int	size_windows:1;		/* Enable root bus sizing */
 	unsigned int	msi_domain:1;		/* Bridge wants MSI domain */
+	unsigned int	broken_l1ss_resume:1;	/* Resuming from L1ss during
+						   system suspend is broken */
 
 	/* Resource alignment requirements */
 	resource_size_t (*align_resource)(struct pci_dev *dev,

-- 
2.51.0

