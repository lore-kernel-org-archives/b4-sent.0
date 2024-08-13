From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 14 Aug 2024 00:24:20 +0800
Subject: [PATCH] ACPI: PCI: check if the io space is page aligned
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240814-check_pci_probe_res-v1-1-122ee07821ab@gmail.com>
X-B4-Tracking: v=1; b=H4sIALSIu2YC/x3M0QpAQBBG4VfRXNtiCHkVaWP9mBTbbElt3t3m8
 rs4J1KACgL1WSTFLUGuM6HMM3L7dG4wsiQTF1wXXVkZt8Md1juxXq8ZVhEMt6jQLGvLM1MqvWK
 V578O4/t+XtUqAGUAAAA=
To: Bjorn Helgaas <bhelgaas@google.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2104;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=DWlqRiPe/fYjvNSchc34mMH7Q4Dr/qB1v12rnVJlSKs=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmu4jBfTWgmYDF3W+Yt0apBYRG6e7gwIu0EY6zA
 47PZgNAN+mJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZruIwQAKCRCwMePKe/7Z
 bhowEADDH2kpqzTz4n37l0QOBIHDygNvWr9UJFn3DVnUaEp9kxAJ/5p5rc347ZwF+qYvcCFty1Z
 yET9MdWuOHxgPoE+ujcPMqvANyfoSpD1ZmaMjmHr1kP7fi0iPraFWbwSkOBagx6Kj8xK8Cxd582
 ZuvP3DK2keZ78PF4HZE7lZkOr+MjxAZ8lSL1TdkIRe2UsdRu0WA0/s+QN0ZsfUIwnRFiME+JHOJ
 msH4Hqumm/rH0wt/jkiKa+LRuSHr4c+K9aB9LEvL3Pt832Yal/GYWWEuYjFGXqXuSGUgrKu+W32
 UW+Ld860zXGsScoHrZmrQykHmhZcWKlUbBzcMlT0ul1giWXiWYgTp4yDrBgfyfRhR0sLIWha9l5
 gN9fvEjPmoZCgnEp+8oc5ELNFGrFxFQOEiXUIb70IEfb1U5c0pB1I5sxkdj6e8mnmFblGgwcgJP
 Lis1rJvtIdWZKVyFD6yCWO9ZD6d7plMUTphSCMEqaRcDLOvxgWQF+SSQB8sI95WrcYHZ3YLgclS
 WlBszCfzc9bpJUxIYQR1jBLjKiIaDEnViBXYaU1+FKBf1DU+xdxWUzIFV3jpK3E6F9Dp4cO3vU5
 yZ0HWYizm4+i6wcK5ndOz/j0B7HTPF/0x9OQfY7divv8+ePl2g/1JweBpDfYHX8/uAiBrNIIW8u
 y8OJaxoNeu7CP0g==
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
 drivers/acpi/pci_root.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/drivers/acpi/pci_root.c b/drivers/acpi/pci_root.c
index d0bfb3706801..58fc64757bde 100644
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
+		dev_err(device->dev,
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

