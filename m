From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Subject: [PATCH 0/2] ata: use named initializers for acpi_device_id
Date: Mon, 03 Aug 2026 16:03:49 +0100
Message-Id: <20260803-ata-acpi-v1-0-f606afaacad1@thegoodpenguin.co.uk>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwNj3cSSRN3E5IJMXUOLNBMD09QkA+NEIyWg8oKi1LTMCrBR0bG1tQC
 HU4P7WgAAAA==
X-Change-ID: 20260803-ata-acpi-18f405eb03a2
To: Hans de Goede <hansg@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785769441; l=1978;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=P13UAEJsNRRy6Sy98EalwJoBjBBrwHcfE7tvLZS+ymM=;
 b=XHOwcvekGno2Y06cozfqQJQXfb65Ercmf8lVahuyeDoZcK1kQjxkI9tYpesJa24XiVbdvrroF
 psAUpnS9ASGA5ChA1/wQwxnuxvrFEbneKPK2G2GWTRAqMXWZcSjh+/t
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
Pawel Zalewski (The Capable Hub) (2):
      ata: use named initializers for acpi_device_id
      ata: ahci_seattle: drop unused acpi_device_id::driver_data

 drivers/ata/ahci_platform.c | 4 ++--
 drivers/ata/ahci_qoriq.c    | 2 +-
 drivers/ata/ahci_seattle.c  | 4 ++--
 drivers/ata/ahci_xgene.c    | 6 +++---
 4 files changed, 8 insertions(+), 8 deletions(-)
---
base-commit: 9ecfb2f7287a967b418ba69f10d45ead0d360593
change-id: 20260803-ata-acpi-18f405eb03a2

Best regards,
-- 
Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>

