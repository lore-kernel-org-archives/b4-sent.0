From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 14 Aug 2024 20:09:15 +0800
Subject: [PATCH v3] ACPI: PCI: check if the root io space is page aligned
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-check_pci_probe_res-v3-1-b6eaa6f99032@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGqevGYC/43NwQrCMAyA4VeRnq206XCdJ99DZLRdtgXdOlopy
 ti72w08CB4kpz+QLzOLGAgjO+1mFjBRJD/mUPsdc70ZO+TU5GYgoBBaKu56dLd6clRPwVusA0Y
 OJSo8Nm0JFli+nAK29NzUyzV3T/Hhw2t7kuS6/XjFTy9JngcAUZQapLHnbjB0Pzg/sNVL8IcB2
 TBCOe0qW1T6y1iW5Q2WAXdS+gAAAA==
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2630;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=6oaDNHVrPEVfrCvEohkLob23Ms2FvyIxaW/2/yHOdZk=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmvJ5s3R3lWYU++7rDe2YItFtoK9N19W9fB8rFh
 +JIF/fxAUmJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZryebAAKCRCwMePKe/7Z
 buu7D/0RUBWCuBb/D16VR1j48OX8MdQFr3MObTJy3QPPNy0Frv+Um02juwAU1oiYtuj//VGhmOo
 2OcUjRRfgXtxGU4IMr4iejr9831igP+Zsk4xcm8stA3bbTY9ogo28RdVwKG2L+VBOLfndG5PPuK
 yNErQUOAsDBVb4ep+r2CRiy37nfh9eZfbyxyosCarQZ31Svdt5RjbmR8iUYGxyGL3qYAMdVKapi
 mVLJijvvpg4Zo7FmE0PADOE2Sqr1RvM/nRrJu62CR+Z9Mn4Tc/N6qZoAp+jBEvNfAjeuvmziWXJ
 JxxCio+kHESbt1y8gB5zHkzy03JcRBuAk4m1T64wkmmhb39pKQuPoc30QUbyHQj8/iJ1zEatEJl
 gpeK0kzFsK0RfSrowh0vP7QrNAwMONZ4TDbYQfkZ3kGnoUFtdWnqiqojMZWzNF1Xf8irOd68UST
 vVUEO/zcuQgcZe/Bzymeo9EA3UH0Jzl+JTfRcTm2aRaZYbWBZSK1aKj+lHNCDVKNaylachEhpq+
 DkqBQ3qgtZFq/qdwK88j5KdRU8veIOxc9dGk0oM8//Mzz0BIdBx6yEHGAUUwja20dQUaDYmlDtO
 s9OBDGHfPtTAEgW3BmQD01VFV+J9a3U0uyvCD1+NGoVqzri7xJHnd4Lvhy0/ISvhVTJlSKLEYqC
 o6ly6PS1nboHxZg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the IO resource given by _CRS method is not page aligned, especially
when the page size is larger than 4KB, serious problems will happen
because the misaligned address is passed down to pci_remap_iospace(),
then to vmap_page_range(), and finally to vmap_pte_range(), where the
length between addr and end is expected to be divisible by PAGE_SIZE, or
the loop will overrun till the pfn_none check fails.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v3:
- Adjust code formatting.
- Reword the commit message for further description of the possible reason
  leading to misaligned IO resource addresses.
- Link to v2: https://lore.kernel.org/r/20240814-check_pci_probe_res-v2-1-a03c8c9b498b@gmail.com

Changes in v2:
- Sorry for posting out the draft version in V1, fixed a silly compiling issue.
- Link to v1: https://lore.kernel.org/r/20240814-check_pci_probe_res-v1-1-122ee07821ab@gmail.com
---
 drivers/acpi/pci_root.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/drivers/acpi/pci_root.c b/drivers/acpi/pci_root.c
index d0bfb3706801..a425e93024f2 100644
--- a/drivers/acpi/pci_root.c
+++ b/drivers/acpi/pci_root.c
@@ -858,7 +858,7 @@ static void acpi_pci_root_validate_resources(struct device *dev,
 	}
 }
 
-static void acpi_pci_root_remap_iospace(struct fwnode_handle *fwnode,
+static void acpi_pci_root_remap_iospace(struct acpi_device *device,
 			struct resource_entry *entry)
 {
 #ifdef PCI_IOBASE
@@ -868,7 +868,15 @@ static void acpi_pci_root_remap_iospace(struct fwnode_handle *fwnode,
 	resource_size_t length = resource_size(res);
 	unsigned long port;
 
-	if (pci_register_io_range(fwnode, cpu_addr, length))
+	if (!PAGE_ALIGNED(cpu_addr) || !PAGE_ALIGNED(length) ||
+	    !PAGE_ALIGNED(pci_addr)) {
+		dev_err(&device->dev,
+			FW_BUG "I/O resource %pR or its offset %pa is not page aligned\n",
+			res, &entry->offset);
+		goto err;
+	}
+
+	if (pci_register_io_range(&device->fwnode, cpu_addr, length))
 		goto err;
 
 	port = pci_address_to_pio(cpu_addr);
@@ -910,7 +918,7 @@ int acpi_pci_probe_root_resources(struct acpi_pci_root_info *info)
 	else {
 		resource_list_for_each_entry_safe(entry, tmp, list) {
 			if (entry->res->flags & IORESOURCE_IO)
-				acpi_pci_root_remap_iospace(&device->fwnode,
+				acpi_pci_root_remap_iospace(device,
 						entry);
 
 			if (entry->res->flags & IORESOURCE_DISABLED)

---
base-commit: 7c626ce4bae1ac14f60076d00eafe71af30450ba
change-id: 20240813-check_pci_probe_res-27e3e6df72b2

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

