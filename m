From: Anthony Ruhier <aruhier@mailbox.org>
Date: Fri, 23 Oct 2026 19:39:35 +0200
Subject: [PATCH] PCI: Disable LTR on Qualcomm WCN7850 [17cb:1107] to allow
 ASPM L1.2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-quick-wcn7850-v1-1-9a139b9b2c8e@mailbox.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNj3cLSzORs3fLkPHMLUwPdRHNLI0szi+RkI9M0JaCegqLUtMwKsHn
 RsRB+cWlSVmpyCcgQpdpaAMlxQMFxAAAA
X-Change-ID: 20261023-quick-wcn7850-a792968cc25f
To: Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anthony Ruhier <aruhier@mailbox.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2159; i=aruhier@mailbox.org;
 s=2026; h=from:subject:message-id;
 bh=qVemxmolshXeAK74vDQvvG7KPXw1hF5ybwiK/r2mOek=;
 b=owGbwMvMwCV2okp4cvOBsLOMp9WSGLJuz37Cz7ZBaGX46ad/bsqxTZD6LcNw0ZBnqkJrwdacm
 1pPv7ct6JjIwiDGxWAppshywbLg8eNb0ZO762y6YOawMoEMkRZpYAACFga+3MS8UiMdIz1TbUM9
 QyBDx4iBi1MApnpDKMP/xMmyzmsuPG+6cth1W+oN4UOPFToOlfhzH0tV85ppVFDLzshw57/Enfl
 ZHiY5m8+oif48uOj39EBP86wX+2UXXYyvvi3JAQA=
X-Developer-Key: i=aruhier@mailbox.org; a=openpgp;
 fpr=F4A378DD8D494AE48EBA554CB00FBC7D08D231D9
X-Endpoint-Received: by B4 Relay for aruhier@mailbox.org/2026 with auth_id=1292
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The WCN7850 Wifi/BT card, found in several Snapdragon X laptops, never
enters ASPM L1.2 when LTR is enabled. Its firmware reads the
LTR_L1.2_THRESHOLD set at enumeration and reports an LTR value just
below it, so the L1.2 entry condition is never met and the link stays in
L1.1.

Windows does not set LTR Mechanism Enable for this device (verified by
dumping the ACPI tables), and the link idles in L1.2 normally.

Replicate the same behavior: clear PCI_EXP_DEVCTL2_LTR_EN for WCN7850 at
enumeration and again on resume, as the LTR state is restored there.

On a Lenovo Yoga Slim 7x (X1E80100) this allows the link to reach L1.2
and reduces idle power by about 70 mW.

Signed-off-by: Anthony Ruhier <aruhier@mailbox.org>
---
 drivers/pci/quirks.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/drivers/pci/quirks.c b/drivers/pci/quirks.c
index 1aa87a3ef9ed..374c505981a0 100644
--- a/drivers/pci/quirks.c
+++ b/drivers/pci/quirks.c
@@ -3795,6 +3795,20 @@ DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_QCOM, 0x1103, quirk_no_bus_reset); /* WCN
 DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_QCOM, 0x1107, quirk_no_bus_reset); /* WCN7850 */
 DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_QCOM, 0x0308, quirk_no_bus_reset); /* SDX62/SDX65 */
 
+/*
+ * The WCN7850 firmware reports an LTR just below the LTR_L1.2_THRESHOLD it
+ * sees at boot, preventing it to ever enter L1.2.
+ * With LTR disabled the link idles in L1.2, similar to what Windows does.
+ */
+static void quirk_wcn7850_disable_ltr(struct pci_dev *pdev)
+{
+	pcie_capability_clear_word(pdev, PCI_EXP_DEVCTL2,
+				   PCI_EXP_DEVCTL2_LTR_EN);
+}
+DECLARE_PCI_FIXUP_FINAL(PCI_VENDOR_ID_QCOM, 0x1107, quirk_wcn7850_disable_ltr);
+DECLARE_PCI_FIXUP_RESUME_EARLY(PCI_VENDOR_ID_QCOM, 0x1107,
+			       quirk_wcn7850_disable_ltr);
+
 /*
  * Root port on some Cavium CN8xxx chips do not successfully complete a bus
  * reset when used with certain child devices.  After the reset, config

---
base-commit: 7be4bc52fd9e0e55dc9a2e0232b89427d2c4b614
change-id: 20261023-quick-wcn7850-a792968cc25f

Best regards,
--  
Anthony Ruhier <aruhier@mailbox.org>

