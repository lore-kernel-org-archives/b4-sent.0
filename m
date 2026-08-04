From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Tue, 04 Aug 2026 10:44:26 +0100
Subject: [PATCH v2] ata: use named initializers for acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-ata-acpi-v2-1-8825e646b80d@thegoodpenguin.co.uk>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23MQQqDMBCF4avIrBuZxFakq95DXEzjRIdCIkmUF
 vHuTV13+T8e3w6Jo3CCe7VD5E2SBF/CXCqwM/mJlYylwaBpscNGUSZFdhGlO3fFGz+xIQPlvkR
 28j6pfig9S8ohfk5507/1D7Jphcq12JIjsjTqR555CmFc2E+r+NqGen3BcBzHF8YrggWrAAAA
X-Change-ID: 20260803-ata-acpi-18f405eb03a2
To: Hans de Goede <hansg@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785836672; l=4772;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=eKY3VkSWVSP8ItVSbKau1mFqa+Js85o/WvNDSrLmjlE=;
 b=1x8Ydb5MdJPX/VJ1QDlTieKz0yDxf6cJ4fV6T96U9UJ87IA4hDAMYPfGI4FdjlNPm2w0eVU9Y
 GcR7oq99JTjAULNrlmhIicqs6Qh9TFzX4xiv+2NmYNyqQamwmRY6YAt
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a named initializer for the acpi_device_id fields which
makes the code more readable and consistent with how lists
are initialized in the rest of the kernel code base. Also
drop explicitly setting fields to 0 where it is redundant.

While we are at it - unify the list terminator to have
a single space between the brackets and no trailing
comma.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
This series is converting lists that contain the acpi_device_id
struct, which is defined in the include/linux/device-id/acpi.h
to makes use of named initializers (which they do not use currently).
This work is part of the on going effort in the kernel associated
with device-ids [1]

The plan is to convert acpi_device_id::driver_data to have an anonymous
union, similarly to what was introduced for PCI and I2C device ID tables.
The goal is to increase type-safety (as most of the existing casts are gone),
to improve readability and to make use intent a bit more clear:

```
union {
	kernel_ulong_t driver_data;
	const void *driver_data_ptr;
}
```

But for that to work all lists containing the structs need to use named
initializers first. I already have patches that implement this and touching
a lot of kernel subsystmes that use the acpi_device_id struct and that list
keeps on growing. Therefore, I have decided to split the series per every
subsystem into:
- pre-clean-ups that convert the lists to use named initializers (this series)
- actual implementations that make some of the modules use the new driver_data_ptr

That way the task can be fragmented into manageable and independent
chunks of work and makes this effort easier to review.

Tested builds on x86-64 in Yocto using 7.2-rc6
---
Changes in v2:
- Fixed up into a single patch
- Link to v1: https://lore.kernel.org/r/20260803-ata-acpi-v1-0-f606afaacad1@thegoodpenguin.co.uk

To: Hans de Goede <hansg@kernel.org>
To: Damien Le Moal <dlemoal@kernel.org>
To: Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/ata/ahci_platform.c | 4 ++--
 drivers/ata/ahci_qoriq.c    | 2 +-
 drivers/ata/ahci_seattle.c  | 4 ++--
 drivers/ata/ahci_xgene.c    | 6 +++---
 4 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/ata/ahci_platform.c b/drivers/ata/ahci_platform.c
index c18054333f7c..d97f0ad3b4cd 100644
--- a/drivers/ata/ahci_platform.c
+++ b/drivers/ata/ahci_platform.c
@@ -88,9 +88,9 @@ static const struct of_device_id ahci_of_match[] = {
 MODULE_DEVICE_TABLE(of, ahci_of_match);
 
 static const struct acpi_device_id ahci_acpi_match[] = {
-	{ "APMC0D33", (unsigned long)&ahci_port_info_nolpm },
+	{ .id = "APMC0D33", .driver_data = (unsigned long)&ahci_port_info_nolpm },
 	{ ACPI_DEVICE_CLASS(PCI_CLASS_STORAGE_SATA_AHCI, 0xffffff) },
-	{},
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ahci_acpi_match);
 
diff --git a/drivers/ata/ahci_qoriq.c b/drivers/ata/ahci_qoriq.c
index 0dec1a17e5b1..96492159fa7c 100644
--- a/drivers/ata/ahci_qoriq.c
+++ b/drivers/ata/ahci_qoriq.c
@@ -80,7 +80,7 @@ static const struct of_device_id ahci_qoriq_of_match[] = {
 MODULE_DEVICE_TABLE(of, ahci_qoriq_of_match);
 
 static const struct acpi_device_id ahci_qoriq_acpi_match[] = {
-	{"NXP0004", .driver_data = (kernel_ulong_t)AHCI_LX2160A},
+	{ .id = "NXP0004", .driver_data = (kernel_ulong_t)AHCI_LX2160A },
 	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ahci_qoriq_acpi_match);
diff --git a/drivers/ata/ahci_seattle.c b/drivers/ata/ahci_seattle.c
index 3f16c1678402..9758fa0260ac 100644
--- a/drivers/ata/ahci_seattle.c
+++ b/drivers/ata/ahci_seattle.c
@@ -178,8 +178,8 @@ static SIMPLE_DEV_PM_OPS(ahci_pm_ops, ahci_platform_suspend,
 			 ahci_platform_resume);
 
 static const struct acpi_device_id ahci_acpi_match[] = {
-	{ "AMDI0600", 0 },
-	{}
+	{ .id = "AMDI0600" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ahci_acpi_match);
 
diff --git a/drivers/ata/ahci_xgene.c b/drivers/ata/ahci_xgene.c
index 98c99b5a8242..2ebfe86e429b 100644
--- a/drivers/ata/ahci_xgene.c
+++ b/drivers/ata/ahci_xgene.c
@@ -710,9 +710,9 @@ static const struct scsi_host_template ahci_platform_sht = {
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id xgene_ahci_acpi_match[] = {
-	{ "APMC0D0D", XGENE_AHCI_V1},
-	{ "APMC0D32", XGENE_AHCI_V2},
-	{},
+	{ .id = "APMC0D0D", .driver_data = XGENE_AHCI_V1 },
+	{ .id = "APMC0D32", .driver_data = XGENE_AHCI_V2 },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, xgene_ahci_acpi_match);
 #endif

---
base-commit: 9ecfb2f7287a967b418ba69f10d45ead0d360593
change-id: 20260803-ata-acpi-18f405eb03a2

Best regards,
--  
Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>

