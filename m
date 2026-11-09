From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Mon, 09 Nov 2026 15:20:52 +0200
Subject: [PATCH] iommu/vt-d: Set up scalable mode context entries for DMA
 aliases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-iommu-vtd-sm-bridge-alias-v1-1-76704f658dc3@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrB0wKhW9SnExSabtFKMloyKId
 zfV5Qfv/TsoR2GFLtsh8ioq05hg8gzch8Y3o/hkKIvyYUzRokwhLLjOHjWgjeLThAYhxZapcc4
 3NVUW0v8X+SXb1X72t3WxX3bzPwjHcQL9pKzpfQAAAA==
X-Change-ID: 20261109-iommu-vtd-sm-bridge-alias-9ea7ccd74a3b
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Kevin Tian <kevin.tian@intel.com>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794230455; l=3605;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=dhz3rHJR7YOUo+roQBNF725wE94t53ubNOSPW8yLvDQ=;
 b=CCaCnLcMIkkJ833TNpgDHDuF6lqomjTQZdvFCQ9qy0RVezMbNjY5HwSKOoRlmEcmNnZBj92e/
 ozmQTn2f9TEDttmf2taiXGkoCtIP5IPgF1ywzfnbC822Hg12pULtuVB
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In scalable mode, devices behind a PCIe-to-PCI bridge can't do DMA at
all. Their requests carry the bridge's alias requester ID, and the
context entry for that ID is never written, so every request faults:

  DMAR: [DMA Read NO_PASID] Request device [0000:02:00.0] fault addr 0xfffff000 [fault reason 0x02] Present bit in context entry is clear

pci_pasid_table_setup() and pci_pasid_table_teardown() only act when
they are called for the device itself. pci_for_each_dma_alias() reports
an alias that comes from an upstream bridge with the bridge as @pdev,
so these aliases are skipped. An identity domain doesn't help either,
as the device still needs the context entry.

Legacy mode is fine, because domain_context_mapping_cb() and
domain_context_clear_one_cb() have no such check, and the same check
was already removed from the pass-through path in commit 64f792981e35
("iommu/vt-d: Remove device comparison in context_setup_pass_through_cb").

Drop it from both callbacks, so the alias context entry points to the
device's PASID table and is cleared again when the device is released.

Fixes: 301f1a80487f ("iommu/vt-d: Setup scalable mode context entry in probe path")
Fixes: 81e921fd3216 ("iommu/vt-d: Fix NULL domain on device release")
Cc: stable@vger.kernel.org
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
This showed up with a USB controller behind QEMU's pcie-pci-bridge in a
q35 guest using intel-iommu with scalable-mode=on: the USB tablet behind
it never enumerates.

Tested on v7.4-rc2 in that guest (x86_64_defconfig + kvm_guest.config,
INTEL_IOMMU with scalable mode on by default), with an EHCI controller
and an e1000 behind the bridge, in scalable mode with second-stage
tables, with first-stage tables (fsts=on) and with iommu=pt. Without
the patch both devices fault on 02:00.0, the tablet never shows up and
the e1000 hits Tx unit hangs. With it the tablet enumerates, the e1000
passes traffic and no DMAR faults are logged. Removing the EHCI
controller through sysfs and rescanning brings it back without faults,
which exercises the teardown side. Legacy mode behaves the same with
and without the patch.

Devices that share an alias always end up in the same IOMMU group, so
whichever device's PASID table the alias entry points to, it translates
with the group's domain. As in legacy mode, releasing one of them also
clears the alias entry the other one uses, so its DMA is blocked until it
is probed again (see the comment above domain_context_clear()).
---
 drivers/iommu/intel/pasid.c | 6 +-----
 1 file changed, 1 insertion(+), 5 deletions(-)

diff --git a/drivers/iommu/intel/pasid.c b/drivers/iommu/intel/pasid.c
index e4f24d3f19a6..e72b6e972cfb 100644
--- a/drivers/iommu/intel/pasid.c
+++ b/drivers/iommu/intel/pasid.c
@@ -760,8 +760,7 @@ static int pci_pasid_table_teardown(struct pci_dev *pdev, u16 alias, void *data)
 {
 	struct device *dev = data;
 
-	if (dev == &pdev->dev)
-		device_pasid_table_teardown(dev, PCI_BUS_NUM(alias), alias & 0xff);
+	device_pasid_table_teardown(dev, PCI_BUS_NUM(alias), alias & 0xff);
 
 	return 0;
 }
@@ -897,9 +896,6 @@ static int pci_pasid_table_setup(struct pci_dev *pdev, u16 alias, void *data)
 {
 	struct device *dev = data;
 
-	if (dev != &pdev->dev)
-		return 0;
-
 	return device_pasid_table_setup(dev, PCI_BUS_NUM(alias), alias & 0xff);
 }
 

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261109-iommu-vtd-sm-bridge-alias-9ea7ccd74a3b

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

