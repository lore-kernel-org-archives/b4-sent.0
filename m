From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 13:41:23 +0530
Subject: [PATCH v2 4/4] nvme-pci: Use pci_suspend_retains_context() API
 during suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-l1ss-fix-v2-4-b2c3a4bdeb15@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2008;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=wkzcjudTR2aJO1tfV1djFAQP7gK0vMlCmcPgSrxkr6g=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDBsv6tg+/ohQFmrGz4V+nYAOWjrvtBggaK5pP
 hOYsITqL6qJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwbLwAKCRBVnxHm/pHO
 9cgHB/9hVy3DtoD01/gYAs2Xvq1Fh82Tk3uM5j/reOXS4YtcDnH3ebdrlkaEcAUK/pUnsUBLMTm
 hx2k/cVOjoyo7IaYJg6epJRiWfULGYwMjvwRCYg+Gs2Nl8sUvOw6JyP8ZEVMXHjE3JbfjAtHhSZ
 /tbF9vEIp3s1e3HX8flKqnnE3Zm6KQ0U0tgU4cazJFSSwleo3ta3nMP/kceK5Mc/njnZHJo1MlX
 OWICXlX4PjD/KE2IYEt7lCDleFJA+0BItGwmbMiuOSF1wyAOOiXxECeZOEMyOj9a5NZ6oSJFf1r
 37bskjeEYIabTMt0JgsZ9OFPwf3A2pk6xE5OYewFC8OtfKPz
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pci_suspend_retains_context() API lets PCI client drivers know if the
platform can retain the device context during suspend. This is decided
based on several factors like:

1. Firmware involvement at the end of suspend
2. Any platform limitation in waking from low power state (L1ss)

And this API might also get extended in the future to cover other platform
specific issues impacting the device low power mode during system suspend.

So use this API instead of checks like pm_suspend_via_firmware(). When this
API returns false, then assume that the platform cannot retain the context
and shutdown the controller. If it returns true, then assume that the
context will be retained and keep the device in low power mode.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/nvme/host/pci.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/pci.c b/drivers/nvme/host/pci.c
index db5fc9bf6627..a6664983ce5d 100644
--- a/drivers/nvme/host/pci.c
+++ b/drivers/nvme/host/pci.c
@@ -3915,6 +3915,7 @@ static int nvme_suspend(struct device *dev)
 	 * use host managed nvme power settings for lowest idle power if
 	 * possible. This should have quicker resume latency than a full device
 	 * shutdown.  But if the firmware is involved after the suspend or the
+	 * platform has any limitation in waking from low power states or the
 	 * device does not support any non-default power states, shut down the
 	 * device fully.
 	 *
@@ -3923,7 +3924,7 @@ static int nvme_suspend(struct device *dev)
 	 * down, so as to allow the platform to achieve its minimum low-power
 	 * state (which may not be possible if the link is up).
 	 */
-	if (pm_suspend_via_firmware() || !ctrl->npss ||
+	if (!pci_suspend_retains_context(pdev) || !ctrl->npss ||
 	    !pcie_aspm_enabled(pdev) ||
 	    (ndev->ctrl.quirks & NVME_QUIRK_SIMPLE_SUSPEND))
 		return nvme_disable_prepare_reset(ndev, true);

-- 
2.48.1

