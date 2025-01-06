From: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
Subject: [PATCH v4 0/2] Add support for Avago/Broadcom APDS9160
Date: Mon, 06 Jan 2025 17:23:00 -0500
Message-Id: <20250106-apds9160-driver-v4-0-f88d9fc45d84@dimonoff.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMRXfGcC/3XNQQ7CIBCF4as0rMUApbR15T2MiwIzlkVLA4Zom
 t5d2o1G6/J/yXwzkwjBQSSnYiYBkovOjznkoSCm78YbUGdzE8GE5Jy3tJtsbLli1AaXINBGGay
 gURbKiuSrKQC6xyZerrl7F+8+PLcHia/rfytxyih2jKm60hI6ebZu8KNHPBo/kJVL4k0Ipn4Jk
 QkNwuhaADa4R5QfBN8hykwY0aIyqmba6i9iWZYXLawuwzcBAAA=
X-Change-ID: 20241119-apds9160-driver-86cf5e86de35
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: Mikael Gonella-Bolduc <m.gonella.bolduc@gmail.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>, 
 Hugo Villeneuve <hvilleneuve@dimonoff.com>, 
 Matti Vaittinen <mazziesaccount@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736202206; l=2816;
 i=mgonellabolduc@dimonoff.com; s=20241119; h=from:subject:message-id;
 bh=EjF1YdbqpBPh4sTCXyvUJoXES+N65/VkVyh/WyOKlAU=;
 b=rhCRyhxP9R3tc9V/gi0aiwV282xjQ9OJwJLz2cHufK0FKqqFUgY5ktAOarD0PLvyxf7PrEqtn
 DsccZt0pflhAWKV4ghbjfcH781Xp7vsxe5m4d1aBMS/vivzLzCWJyEh
X-Developer-Key: i=mgonellabolduc@dimonoff.com; a=ed25519;
 pk=p4tvPfGPfXRyChsgHc6s7HwB6YBl2JqqcP3BXtoDitE=
X-Endpoint-Received: by B4 Relay for mgonellabolduc@dimonoff.com/20241119 with auth_id=279
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

APDS9160 is an ALS and proximity sensor.
https://www.broadcom.com/products/optical-sensors/integrated-ambient-light-and-proximity-sensors/apds-9160-003

Signed-off-by: Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>
---
Changes in v4:
- dt-bindings: Add additional analog cancellation properties
- driver: Using analog cancellation properties from device tree
- driver: Changed proximity channel type calibscale to calibbias
- driver: Fixed some comments format
- Link to v3: https://lore.kernel.org/r/20241216-apds9160-driver-v3-0-c29f6c670bdb@dimonoff.com

Changes in v3:
- Updated maintainers file email and vendor
- Corrected documentation file reference
- dt-bindings: Changed commit message
- driver: Added event and channel table when irq is not used
- driver: Using int time instead of sampling freq for proximity channel
- driver: Using scale instead of hardwaregain for proximity channel
- driver: Dropped unused static variables
- driver: Fixed switch fall-through
- driver: Dropped explicit void pointer cast
- driver: Dropped some less relevant comments
- driver: Various code style related fix
- Link to v2: https://lore.kernel.org/r/20241206-apds9160-driver-v2-0-be2cb72ef8f4@dimonoff.com

Changes in v2:
- Rebased on linux-iio 20fd1383
- dt-bindings: Dropped the old Avago name and use the brcm vendor prefix
- dt-bindings: Updated example node name with a generic name
- dt-bindings: Updated example indentation to 4 spaces
- dt-bindings: Fixed element ordering
- KConfig: Dropped unsure sentences
- KConfig: Dropped unused Kfifo buffer selection
- driver: Use a more recent iio light driver as template
- driver: Remove buffer declaration
- driver: Use avail functions instead of custom iio attributes
- driver: Use scale instead of hardware gain
- driver: Removed unused members and unreachable statements
- driver: Removed unnecessary info and debug prints
- driver: Fix some coding style and line wrapping issues
- driver: Reordering of functions
- Link to v1: https://lore.kernel.org/r/20241119-apds9160-driver-v1-0-fa00675b4ea4@dimonoff.com

---
Mikael Gonella-Bolduc (2):
      dt-bindings: iio: light: Add APDS9160 binding
      iio: light: Add APDS9160 ALS & Proximity sensor driver

 .../bindings/iio/light/brcm,apds9160.yaml          |   86 ++
 MAINTAINERS                                        |    7 +
 drivers/iio/light/Kconfig                          |   11 +
 drivers/iio/light/Makefile                         |    1 +
 drivers/iio/light/apds9160.c                       | 1586 ++++++++++++++++++++
 5 files changed, 1691 insertions(+)
---
base-commit: 5de07b8a24cf44cdb78adeab790704bf577c2c1d
change-id: 20241119-apds9160-driver-86cf5e86de35

Best regards,
-- 
Mikael Gonella-Bolduc <mgonellabolduc@dimonoff.com>

