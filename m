From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 14 Aug 2024 00:39:56 +0800
Subject: [PATCH v2] ACPI: PCI: check if the io space is page aligned
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-check_pci_probe_res-v2-1-a03c8c9b498b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFuMu2YC/22NwQqDMBBEf0X23BSzSpWe+h8iIcZVl1YTkhJaJ
 P/eVOitzOkNzJsdAnmmANdiB0+RA9stA54KMIveZhI8ZgYssS5bWQmzkLkrZ1g5bwdSnoLAhiq
 6jFODA0JeOk8Tvw5r12deODytfx8nUX7bn6/+64tS5CASlU2LUg+3edX8OBu7Qp9S+gA+2jwqt
 gAAAA==
To: Bjorn Helgaas <bhelgaas@google.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2305;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=0ZF6Ci0GjEHWbF0h9iTGy8xDpgABqmqlKbAHXnzVJoM=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmu4xelt/qz9EDOzhpIjWxWhbApkRhd5AgosWCm
 qkMnNroN+mJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZruMXgAKCRCwMePKe/7Z
 bvLJEADA9XNjIMty4vKg9m7BU2OcV9c2MdfE/u9irh9gmrO1sdmMHZgOX1MP6B/GU1CkT3D3f5H
 G4zlWQjEw2M/syzvDMUyPnrwPBX7JG+ucX1oNDhPFXa16N+Nw7KMn6MGO1Fcis3AgmwKCCXNaOL
 vvv5Fk5G4AcBhqbIqe4xSv0iiYA9q6XkoDb5ssXGbV9PTdKDouWSvIkgOe4K1wwq0C6mTjjTgQO
 HIxd9aL7DJmgeF74x+R3ODhCGOhNLJW0rWuta2dHCZIA6bzJj1jYHLZKwxZoXeWrwT5qxnKW9BB
 dDt3gHk83p1lBsERi9EdSV80qirzx6YzkquUr/abM3++b+OcSJQ7H/u/8HoFM9RAaOSVen1Yx26
 GxYl++Lm7wVn5P4q7L7ouzTxU5P+eXLjmIyzNiapQqFQ21yYOlD5JQFF7kp0T1aqhJe+4cwl9fu
 wkSot6h0vb2xntW3DcsmUzJe5iWoslmPK2T6yNz3uyqg/Tnbmx5wefFZptEjHcX0L5W0BRaBZmj
 JFn/Qv5yKU6xS7s+D/tmDKEusaDbqTW5keXjK7DxgsKfgHuXSZd/ixhF/zui91Ojd6fh+HdlyYp
 8EtrgvxqEWdGsonS0Oh3pS33cRlkFcPTR3C3Ao/ZPAjXeLHt3gavx+HDRdumtiDd8IVI4x93MfI
 PVbuMJY/P49rXUw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the IO resource given by _CRS method is not page aligned, serious
problems will happen because the mis-aligend address is passed down to
pci_remap_iospace, then to vmap_page_range, and finally to
vmap_pte_range, where the length bewteen addr and end is expected to be
divisible by PAGE_SIZE, or the loop will overrun till the pfn_none check
fails.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v2:
- Sorry for posting out the draft version in V1, fixed a silly compiling issue.
- Link to v1: https://lore.kernel.org/r/20240814-check_pci_probe_res-v1-1-122ee07821ab@gmail.com
---
 drivers/acpi/pci_root.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/drivers/acpi/pci_root.c b/drivers/acpi/pci_root.c
index d0bfb3706801..706449e5f29b 100644
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
+		!PAGE_ALIGNED(pci_addr)) {
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

