From: Remy Demangeot <remy@demangeot.net>
Subject: [PATCH v2 0/2] ACPI: EC / hwmon: (asus-ec-sensors) use ec.c for
 the MAXIMUS IX EXTREME second EC
Date: Thu, 29 Oct 2026 08:48:01 +0100
Message-Id: <20261029-m9e-ec2-v2-0-e9c4e2ba8415@demangeot.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADH64moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNL3VzLVN3UZCNdM4u0xBSLZAOLFNNEJaDqgqLUtMwKsEnRsbW1AAc
 o8PtZAAAA
X-Change-ID: 20261029-m9e-ec2-68fad8c08d5a
To: "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Eugene Shalygin <eugene.shalygin@gmail.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Armin Wolf <W_Armin@gmx.de>, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 Remy Demangeot <remy@demangeot.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793260087; l=2311;
 i=remy@demangeot.net; s=20261015; h=from:subject:message-id;
 bh=z+w564HyFM1lLPV34H4icOPYBFIvAz6TuRX2u+dKWfU=;
 b=aWrCl5x543W+pi92xTuPxHgyNVsc7khzeafqzXyDMClsGaoTgttfZh5kCWvPQjHsakxdKVYwG
 1l07sVkAwtUDr+Jz4jmLqS0nQHtgb5i4NJW44FZLOT2XlXr01giSvI3
X-Developer-Key: i=remy@demangeot.net; a=ed25519;
 pk=h/s5N2ZlgZ0m+8FpMhSaCNJt0jvb9whRBAdJwpC+VAo=
X-Endpoint-Received: by B4 Relay for remy@demangeot.net/20261015 with auth_id=1194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This replaces patch 3/3 of the series "hwmon: (asus-ec-sensors) more
MAXIMUS IX EXTREME sensors" [1]. Patches 1/3 and 2/3 of that series
only use the main EC and are unchanged.

Eugene asked to operate the second EC through drivers/acpi/ec.c rather
than re-implementing the EC protocol in the driver [2]. Patch 1 adds a
small API to ec.c for an EC that is not described in the ACPI tables:
acpi_ec_create_polled() / acpi_ec_destroy_polled() and byte accessors.
Such an EC only uses busy polling: no GPE, no IRQ, no query events and
no address space handler. Patch 2 uses it in asus-ec-sensors.

To answer Armin's question [3]: no, this EC is not described in the
ACPI tables of this board (BIOS 1501). There is no PNP0C09 device for
it; only the WMI method \_SB.AMW0.WLDF writes to ports 0x68/0x6c
directly, without taking any lock. The other PNP0C09 device, H_EC, is
a reference-code stub whose _STA returns 0.

Guenter, please drop v1 3/3: it sorted the sensor banks as signed
values, so the second EC bank came first, the second EC was never set
up, and no sensor of the board could be read anymore. This is fixed in
patch 2 and was found while testing this series.

Both patches were tested on a MAXIMUS IX EXTREME with Secure Boot
enabled: the four water temperatures read correctly, 300
consecutive reads gave no error, and the I/O ports are released and
requested again when the module is reloaded.

Patch 1 needs an ack from the ACPI side; patch 2 depends on it.

[1] https://lore.kernel.org/r/20261026-b4-m9e-ext-sensors-v1-0-644d389b2de1@demangeot.net
[2] https://lore.kernel.org/r/CAB95QAQaogxV6KO5kpv9RBpzhhmH_N3Dvvy=nqWHOG6qAQB_aw@mail.gmail.com
[3] Armin Wolf, reply to v1 3/3, 28 Oct 2026

---
Remy Demangeot (2):
      ACPI: EC: allow drivers to create a polled EC
      hwmon: (asus-ec-sensors) add water temperatures for MAXIMUS IX EXTREME

 drivers/acpi/ec.c               |  89 ++++++++++++++++++++++++++++++++-
 drivers/hwmon/asus-ec-sensors.c | 108 ++++++++++++++++++++++++++++++++++------
 include/linux/acpi.h            |   8 +++
 3 files changed, 189 insertions(+), 16 deletions(-)
---
base-commit: b27578907b9dd74db5e9b397bf063c43719c162b
change-id: 20261029-m9e-ec2-68fad8c08d5a

Best regards,
-- 
Remy Demangeot <remy@demangeot.net>

