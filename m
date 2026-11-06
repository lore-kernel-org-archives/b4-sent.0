From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Fri, 06 Nov 2026 12:09:59 +0100
Subject: [PATCH RFC] power: sequencing: pcie-m2: stop requiring subsystem
 IDs for WCN6855/WCN7850
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-pwrseq-bt-subsystem-v1-1-11fb09f63c93@oldschoolsolutions.biz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwMz3YLyouLUQt2kEt3i0qTiyuKS1FxdIxPLZHOLVAsDo+QkJaDOgqL
 UtMwKsKnRSkFuzkqxtbUAp1bYMWoAAAA=
X-Change-ID: 20261106-pwrseq-bt-subsystem-249c78e802cb
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Wei Deng <wei.deng@oss.qualcomm.com>
Cc: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 linux-pci@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793963402; l=3002;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=t5UII2v99mLuMKVxGQklvEBJsKKUJFSN4tb1ImMhs0k=;
 b=w/e8/FRzz6dIH+oxyAlLxQfsWrqcdJm7iFVI1QuyVeFH6PoCpRsMpGN4qOtU3cdHjsY+ll4Dk
 DkK+mUkRAs6AXl5Gv9xCUltGGe9clDlEvEBWvC18dFgvMdomfojfkol
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a39ac4651e3b ("power: sequencing: pcie-m2: Match WCN6855 and
WCN7851 UART BT variants by subdevice ID") narrowed the PCI match for
the WCN6855/WCN7850 family from PCI_DEVICE() to PCI_DEVICE_SUB() in
order to avoid creating a UART serdev on USB-BT variants that share
the same device ID.

The practical result is that every legitimate UART-BT board must now be
explicitly listed. Missing entries (e.g. Lenovo T14s Gen 6, subsystem
17aa:e0e9) silently prevent serdev creation even though the DT graph
already describes a UART link on the connector.

The graph link is the reliable signal that a UART BT interface exists.
Once it is present, the vendor + device ID is sufficient to select the
correct compatible string for the dynamically created node. A pure
USB-BT card simply has no UART graph endpoint, so no serdev is created.

Keep a single PCI_DEVICE_SUB() entry for the QCA2066 (which shares the
1103 ID but needs distinct BT driver data) and fall back to bare
PCI_DEVICE() matches for the rest of the 1103 and 1107 families.

This removes the growing OEM subsystem-ID catalog from the critical
path while preserving the one case that actually needs a subsystem
distinction.

Fixes: a39ac4651e3b ("power: sequencing: pcie-m2: Match WCN6855 and WCN7851 UART BT variants by subdevice ID")

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 10 ++--------
 1 file changed, 2 insertions(+), 8 deletions(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index 56c5d51293c10..72c721149dfae 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -217,15 +217,9 @@ static const struct pci_device_id pwrseq_m2_pci_ids[] = {
 	  .driver_data = (kernel_ulong_t)"nxp,88w8987-bt" },
 	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1103, PCI_VENDOR_ID_QCOM, 0x0108),
 	  .driver_data = (kernel_ulong_t)"qcom,qca2066-bt" },
-	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1103, PCI_VENDOR_ID_FOXCONN, 0xe105),
+	{ PCI_DEVICE(PCI_VENDOR_ID_QCOM, 0x1103),
 	  .driver_data = (kernel_ulong_t)"qcom,wcn6855-bt" },
-	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1103, PCI_VENDOR_ID_QCOM, 0x337e),
-	  .driver_data = (kernel_ulong_t)"qcom,wcn6855-bt" },
-	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1107, PCI_VENDOR_ID_QCOM, 0x337c),
-	  .driver_data = (kernel_ulong_t)"qcom,wcn7850-bt" },
-	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1107, PCI_VENDOR_ID_LENOVO, 0xe0e9),
-	  .driver_data = (kernel_ulong_t)"qcom,wcn7850-bt" },
-	{ PCI_DEVICE_SUB(PCI_VENDOR_ID_QCOM, 0x1107, PCI_VENDOR_ID_FOXCONN, 0xe0ee),
+	{ PCI_DEVICE(PCI_VENDOR_ID_QCOM, 0x1107),
 	  .driver_data = (kernel_ulong_t)"qcom,wcn7850-bt" },
 	{ } /* Sentinel */
 };

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261106-pwrseq-bt-subsystem-249c78e802cb

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

