From: Frank Li <Frank.Li@nxp.com>
Date: Thu, 10 Jul 2025 15:13:50 -0400
Subject: [PATCH v21 4/9] PCI: endpoint: pci-ep-msi: Add MSI address/data
 pair mutable check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250710-ep-msi-v21-4-57683fc7fb25@nxp.com>
References: <20250710-ep-msi-v21-0-57683fc7fb25@nxp.com>
In-Reply-To: <20250710-ep-msi-v21-0-57683fc7fb25@nxp.com>
To: Kishon Vijay Abraham I <kishon@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Anup Patel <apatel@ventanamicro.com>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Arnd Bergmann <arnd@arndb.de>, 
 Shuah Khan <shuah@kernel.org>, Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>
Cc: Niklas Cassel <cassel@kernel.org>, dlemoal@kernel.org, jdmason@kudzu.us, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-pci@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 imx@lists.linux.dev, devicetree@vger.kernel.org, 
 Niklas Cassel <cassel@kernel.org>, Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752174836; l=1452;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=5GnLijRH62gBTUdnVBRu9d7hyvLf0+eT6hrBiV+MYG4=;
 b=L2fisuczw40QBhMHVWvKZlHl+ivJhSeTrPDRL1yujDkngHoAuZxODt+gGwgTwwaumwaPHxAJ8
 IIude4pEMWeALEBm43Q6meOerlETZX6WDL9ailiwfhENDBtlJl0z8Dr
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some MSI controller change address/data pair when irq_set_affinity().
Current PCI endpoint can't support this type MSI controller. Call
irq_domain_is_msi_immutable() check if address/data pair immutable.

Also ensure it is parent MSI domains, not device-specific MSI domains,
since device MSI domains do not allocate address/data pairs.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
change in v20
- update commit message
- change return error code to ENODEV

change in v18
- update commit message. remove 'include/linux/msi.h' part.

change from v14 to v17
- none

change from  v13 to v14
- bring v10 back

Change from v9 to v10
- new patch
---
 drivers/pci/endpoint/pci-ep-msi.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/pci/endpoint/pci-ep-msi.c b/drivers/pci/endpoint/pci-ep-msi.c
index de610c16f68986eb0a5f4a0f23bd0136aa169f97..2b4405cfeb6f8f3cbe9782c793604a10dcaa4eb7 100644
--- a/drivers/pci/endpoint/pci-ep-msi.c
+++ b/drivers/pci/endpoint/pci-ep-msi.c
@@ -55,6 +55,14 @@ int pci_epf_alloc_doorbell(struct pci_epf *epf, u16 num_db)
 		return -ENODEV;
 	}
 
+	if (!irq_domain_is_msi_parent(dom))
+		return -ENODEV;
+
+	if (!irq_domain_is_msi_immutable(dom)) {
+		dev_err(dev, "MSI controller not supported\n");
+		return -ENODEV;
+	}
+
 	dev_set_msi_domain(epc->dev.parent, dom);
 
 	msg = kcalloc(num_db, sizeof(struct pci_epf_doorbell_msg), GFP_KERNEL);

-- 
2.34.1

