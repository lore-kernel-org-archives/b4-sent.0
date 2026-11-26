From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v4 0/3] Add Cortina Systems CS7542 NAND controller support
Date: Thu, 26 Nov 2026 15:45:26 +0300
Message-Id: <20261126-b4-cs7542-nand-v4-0-38e488f6f8b1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBCF4auQrq2ZaQulrryHcQFlgBoBQ5FoC
 He34IZodPmS+f6ZmKfekWeHaGI9jc67rg1D7SJm66ytiLsibCZAJIhC8lxx63WsBG+ztuCpNka
 TBABtWEC3nkr3WIOn83v7e34hOyyV5aJ2fuj65/pxxOXuZ3xEDlxbQm0sIJI4Vk3mrnvbNWyJj
 +I/F4GbwpSQJpDGUn1yueXxF5eBQ54UqNAiCNryeZ5fz+BxRjwBAAA=
X-Change-ID: 20261123-b4-cs7542-nand-87997e300079
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mtd@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795697127; l=4360;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=wQpDUS5b0pYxv/jtguM6xqTqewPkbwxTjWJdoV23J8Q=;
 b=jqEQpn7bmgur8voLImXxF37PWNK0HpjRiGsLyBN4uiuJJihAoHnmHnl3GluetgtBhgI7lX6nt
 SPCdr2NXWWYAKi4UePZq3FYhHXk+UC5byzS29/F4RokceCacFl7OIdM
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CS7542 programmed-I/O NAND controller independently of the
platform series and ARCH_CORTINA_ACCESS.

Describe the hardware's two chip selects, 8/16-bit bus and Hamming/BCH
capabilities in the binding. The initial driver supports one connected
8-bit target on either CS, on-host Hamming with 256-byte steps, software
ECC and raw operation. It preserves firmware bus timing by retaining
the AXI clock rate. The optional flash reset is acquired without a pulse;
PIO polls completion without claiming the flash IRQ or shared SSP DMA.

Validate generic operation descriptors separately from execution. Use
NAND core page-operation builders in the hardware ECC callbacks instead
of assembling read/program opcodes independently. Preserve the existing
Almond+ Hamming/OOB layout.

Validation of this v4 candidate:
- Full ARM vmlinux/modules builds with the driver =y and =m, without the
  platform series and with COMPILE_TEST=n; software Hamming enabled.
- Binding/example validation and strict source checkpatch.
- Actual NAND core builders and the driver validator: 9815 cases each
  against native and OpenWrt 6.18 headers, GCC and Clang ASan/UBSan.
- Actual hardware-ECC sequencing versus v3: 240 cases per compiler,
  including command/address registers, CS/bank selection, main/ECC/OOB
  ordering and fault cleanup.
- Exact driver compilation with the installed OpenWrt 6.18.64 headers.

The exact new NAND driver booted on Almond+ in a combined OpenWrt
6.18.64 RAM kernel. It read 56 MiB of protected regions with matching
SHA-256 and matched raw/generic 64-byte OOB reads in all four banks.
The real UBI stack created a temporary two-LEB volume, wrote/compared
two 253952-byte patterns, physically erased both LEBs and read back ff.
The temporary volume was removed and the normal reserve restored to
80 blocks (free 0/bad 0, original five volumes intact). The independent
fixed-deadline watchdog returned to installed OpenWrt automatically;
all 13 protected hashes and all configuration hashes matched, and the
four LCD services and normal 30-second watchdog were running.

The RAM run tested the retained hardware Hamming layout. Software ECC
was checked by compilation and the core-operation host tests, rather
than changing the ECC format of the existing flash. No kernel image
was installed by the RAM test. Native driver source bytes were identical
to the tested 6.18 integration; the native full builds are separate.

---
Changes in v4:
- Address Miquel Raynal's binding and driver review on v2.
- Describe controller capabilities rather than only the initial driver.
- Add the AXI clock, flash IRQ, optional reset and data aperture binding.
- Separate supports_op() and remove the NAND opcode whitelist.
- Use core page helpers for hardware ECC; allow software ECC/raw transfers.
- Support either chip select and reject multiple connected targets explicitly.
- Preserve bus timing through clock rate exclusivity; do not pulse flash reset.
- Clarify the vendor EXTADDR convention; retain the existing Hamming layout.
- Link to v3: https://patch.msgid.link/20261125-b4-cs7542-nand-v3-0-0b6d141c102e@gmail.com

To: Fil Dunsky <filipp.dunsky@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>
To: Richard Weinberger <richard@nod.at>
To: Vignesh Raghavendra <vigneshr@ti.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mtd@lists.infradead.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (3):
      dt-bindings: mtd: Add Cortina CS7542 NAND controller
      mtd: rawnand: Add Cortina CS7542 controller support
      MAINTAINERS: Add Cortina CS7542 NAND controller entry

 .../bindings/mtd/cortina,cs7542-nand.yaml          |  90 +++
 MAINTAINERS                                        |   7 +
 drivers/mtd/nand/raw/Kconfig                       |  12 +
 drivers/mtd/nand/raw/Makefile                      |   1 +
 drivers/mtd/nand/raw/cs752x_nand.c                 | 743 +++++++++++++++++++++
 5 files changed, 853 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-nand-87997e300079

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

