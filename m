From: Yu Yang <yuyang@kylinos.cn>
Date: Mon, 09 Nov 2026 17:24:28 +0800
Subject: [PATCH] PCI/MSI: Skip address mask check for MSI-X entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-pci-fix-msix-alloc-failure-v1-1-6370c0b84354@kylinos.cn>
X-B4-Tracking: v=1; b=H4sIAEuR8WoC/x2MSQqAMAwAvyI5G7A9uH1FPJQ20UBdaFGE4t8NX
 gYGhimQKQllGKsCiW7Jcuwqpq7Ar25fCCWog21sa0wz4OkFWR7cssLFeHhkJ/FKhD4wU+Cho96
 CDs5EWv7zaX7fDxH2mldsAAAA
X-Change-ID: 20261109-pci-fix-msix-alloc-failure-cdffedf97e82
To: Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, Thomas Gleixner <tglx@kernel.org>, 
 Michael Ellerman <mpe@ellerman.id.au>, 
 Brett Creeley <brett.creeley@amd.com>, Shannon Nelson <sln@onemain.com>, 
 linux-kernel@vger.kernel.org, Yu Yang <yuyang@kylinos.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794216287; l=2146;
 i=yuyang@kylinos.cn; s=20261109; h=from:subject:message-id;
 bh=fq57q40/5O4bXqj13wzHAYXlVx1mOt/jNhP7ggzzvwU=;
 b=HmUWeekm6t09OjI/k6Xpy3e41nbV6rOobI0E6lAx7TjPCaJo+xung/OaZDLhu3v8VVnLnWEs4
 9y7toDvn/GbC1cDslIZz2I/OGVc06h4NcnugXpxwzH14DUZ6oz8TcZj
X-Developer-Key: i=yuyang@kylinos.cn; a=ed25519;
 pk=LQAY8k9sUwvjwxS9P2CQE0GbrKw/MJPJbDHlapWOZ8A=
X-Endpoint-Received: by B4 Relay for yuyang@kylinos.cn/20261109 with auth_id=1458
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AHCI controller on Zhaoxin ZX-200 platforms supports only 32-bit
MSI addresses, but its MSI-X capability uses 64-bit message addresses.
pci_msi_init() therefore sets dev->msi_addr_mask to DMA_BIT_MASK(32)
based on the MSI capability.

msi_verify_entries() is shared between the MSI and MSI-X setup paths.
When the irq domain assigns an MSI-X message address above 4GB, the
32-bit mask inherited from the MSI capability causes MSI-X setup to
fail with -EIO:

  ahci 0000:09:0f.0: arch assigned 64-bit MSI address 0x8002a030040
  above device MSI address mask 0xffffffff.
  ...
  ahci: probe of 0000:09:0f.0 failed with error -22.

MSI-X table entries have a 64-bit message address field, so the 32-bit
limit derived from the MSI capability does not apply to them.
Platforms that use msi_addr_mask to constrain MSI-X allocation, e.g.
powerpc pseries/powernv and ionic on PPC64, already allocate addresses
that satisfy the mask, so the verification is redundant for MSI-X.

Skip the address mask check for MSI-X descriptors.

Fixes: f144d1496b47 ("PCI/MSI: Add device flag indicating that 64-bit MSIs don't work")

Signed-off-by: Yu Yang <yuyang@kylinos.cn>
---
 drivers/pci/msi/msi.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/pci/msi/msi.c b/drivers/pci/msi/msi.c
index 8a0133a6a286..7f34bccc8248 100644
--- a/drivers/pci/msi/msi.c
+++ b/drivers/pci/msi/msi.c
@@ -338,6 +338,13 @@ static int msi_verify_entries(struct pci_dev *dev)
 		return 0;
 
 	msi_for_each_desc(entry, &dev->dev, MSI_DESC_ALL) {
+		/*
+		 * MSI-X entries always use a 64-bit address, so the address
+		 * limit for MSI capability does not apply for MSI-X.
+		 */
+		if (entry->pci.msi_attrib.is_msix)
+			continue;
+
 		address = (u64)entry->msg.address_hi << 32 | entry->msg.address_lo;
 		if (address & ~dev->msi_addr_mask) {
 			pci_err(dev, "arch assigned 64-bit MSI address %#llx above device MSI address mask %#llx\n",

---
base-commit: 996a59519af2ef3d8f47479685616bb2278c6cfa
change-id: 20261109-pci-fix-msix-alloc-failure-cdffedf97e82

Best regards,
-- 
Yu Yang <yuyang@kylinos.cn>

