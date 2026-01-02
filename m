From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Fri, 02 Jan 2026 21:04:48 +0530
Subject: [PATCH v3 2/4] PCI: Cache ACS capabilities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260102-pci_acs-v3-2-72280b94d288@oss.qualcomm.com>
References: <20260102-pci_acs-v3-0-72280b94d288@oss.qualcomm.com>
In-Reply-To: <20260102-pci_acs-v3-0-72280b94d288@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 iommu@lists.linux.dev, Naresh Kamboju <naresh.kamboju@linaro.org>, 
 Pavankumar Kondeti <quic_pkondeti@quicinc.com>, 
 Xingang Wang <wangxingang5@huawei.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Robin Murphy <robin.murphy@arm.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3840;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=WNlj98gnBzP8GjtkwGPs6wt/sfHp/QN3NSkkvAVIXtQ=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpV+Wm0uuebZ0Bh1aSfHkMGH9dvwjaLhS2WLos/
 KSkWbsN2gGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVflpgAKCRBVnxHm/pHO
 9YEYCACMjcDP3uQy0Rj+omfbOFgbTz9mNX1Y7XE/+f9xXOBH62vc22vblxpTSfhMSx02s0p6qyg
 WflootAkgPcpAHnDnd0buKCGWFaJojNQRNnznfPCPXqs+gQ+P8EuHsXl86dt2QGDdabPjq9kXqv
 eY95BzcfEWzCczMSWsre8o0ApDv9PYjcPe0hkmhxI1RfI9OSX8JRRMkaXHyX4o+crl0NrGJieK7
 v6bOx7gG1Dk1Y0E6lIkqNI2SKZz1/ggKgEfJh8MZCRRsFtft9s9zzeHP0YUFpwhs5b9RHwSjMxI
 eeMXMyQQMTVOqykGwdF7ZTE1jOwK2uoihGk1gLonxQfuaUAS
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ACS capabilities are the RO values set by the hardware. Cache them to avoid
reading it all the time when required and also to override any capability
in quirks.

Tested-by: Marek Szyprowski <m.szyprowski@samsung.com>
Tested-by: Naresh Kamboju <naresh.kamboju@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pci.c   | 26 +++++++++++++++-----------
 include/linux/pci.h |  1 +
 2 files changed, 16 insertions(+), 11 deletions(-)

diff --git a/drivers/pci/pci.c b/drivers/pci/pci.c
index 2c3d0a2d6973..d89b04451aea 100644
--- a/drivers/pci/pci.c
+++ b/drivers/pci/pci.c
@@ -892,7 +892,6 @@ static const char *disable_acs_redir_param;
 static const char *config_acs_param;
 
 struct pci_acs {
-	u16 cap;
 	u16 ctrl;
 	u16 fw_ctrl;
 };
@@ -995,27 +994,27 @@ static void __pci_config_acs(struct pci_dev *dev, struct pci_acs *caps,
 static void pci_std_enable_acs(struct pci_dev *dev, struct pci_acs *caps)
 {
 	/* Source Validation */
-	caps->ctrl |= (caps->cap & PCI_ACS_SV);
+	caps->ctrl |= (dev->acs_capabilities & PCI_ACS_SV);
 
 	/* P2P Request Redirect */
-	caps->ctrl |= (caps->cap & PCI_ACS_RR);
+	caps->ctrl |= (dev->acs_capabilities & PCI_ACS_RR);
 
 	/* P2P Completion Redirect */
-	caps->ctrl |= (caps->cap & PCI_ACS_CR);
+	caps->ctrl |= (dev->acs_capabilities & PCI_ACS_CR);
 
 	/* Upstream Forwarding */
-	caps->ctrl |= (caps->cap & PCI_ACS_UF);
+	caps->ctrl |= (dev->acs_capabilities & PCI_ACS_UF);
 
 	/* Enable Translation Blocking for external devices and noats */
 	if (pci_ats_disabled() || dev->external_facing || dev->untrusted)
-		caps->ctrl |= (caps->cap & PCI_ACS_TB);
+		caps->ctrl |= (dev->acs_capabilities & PCI_ACS_TB);
 }
 
 /**
  * pci_enable_acs - enable ACS if hardware support it
  * @dev: the PCI device
  */
-static void pci_enable_acs(struct pci_dev *dev)
+void pci_enable_acs(struct pci_dev *dev)
 {
 	struct pci_acs caps;
 	bool enable_acs = false;
@@ -1031,7 +1030,6 @@ static void pci_enable_acs(struct pci_dev *dev)
 	if (!pos)
 		return;
 
-	pci_read_config_word(dev, pos + PCI_ACS_CAP, &caps.cap);
 	pci_read_config_word(dev, pos + PCI_ACS_CTRL, &caps.ctrl);
 	caps.fw_ctrl = caps.ctrl;
 
@@ -3514,7 +3512,7 @@ void pci_configure_ari(struct pci_dev *dev)
 static bool pci_acs_flags_enabled(struct pci_dev *pdev, u16 acs_flags)
 {
 	int pos;
-	u16 cap, ctrl;
+	u16 ctrl;
 
 	pos = pdev->acs_cap;
 	if (!pos)
@@ -3525,8 +3523,7 @@ static bool pci_acs_flags_enabled(struct pci_dev *pdev, u16 acs_flags)
 	 * or only required if controllable.  Features missing from the
 	 * capability field can therefore be assumed as hard-wired enabled.
 	 */
-	pci_read_config_word(pdev, pos + PCI_ACS_CAP, &cap);
-	acs_flags &= (cap | PCI_ACS_EC);
+	acs_flags &= (pdev->acs_capabilities | PCI_ACS_EC);
 
 	pci_read_config_word(pdev, pos + PCI_ACS_CTRL, &ctrl);
 	return (ctrl & acs_flags) == acs_flags;
@@ -3647,7 +3644,14 @@ bool pci_acs_path_enabled(struct pci_dev *start,
  */
 void pci_acs_init(struct pci_dev *dev)
 {
+	int pos;
+
 	dev->acs_cap = pci_find_ext_capability(dev, PCI_EXT_CAP_ID_ACS);
+	pos = dev->acs_cap;
+	if (!pos)
+		return;
+
+	pci_read_config_word(dev, pos + PCI_ACS_CAP, &dev->acs_capabilities);
 }
 
 /**
diff --git a/include/linux/pci.h b/include/linux/pci.h
index 864775651c6f..6195e040b29c 100644
--- a/include/linux/pci.h
+++ b/include/linux/pci.h
@@ -558,6 +558,7 @@ struct pci_dev {
 	struct pci_tsm *tsm;		/* TSM operation state */
 #endif
 	u16		acs_cap;	/* ACS Capability offset */
+	u16		acs_capabilities; /* ACS Capabilities */
 	u8		supported_speeds; /* Supported Link Speeds Vector */
 	phys_addr_t	rom;		/* Physical address if not from BAR */
 	size_t		romlen;		/* Length if not from BAR */

-- 
2.48.1

