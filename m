From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v5 0/3] Add Cortina Systems CS7542 NAND controller support
Date: Fri, 27 Nov 2026 18:54:03 +0300
Message-Id: <20261127-b4-cs7542-nand-v5-0-45b1a92bd13d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ6CMBCG4auYrq2ZaUt/XHkP4wLKoDUKhiLRE
 O5uwQ3R6PJL5nlnYJHaQJFtVwNrqQ8xNHUa2XrF/Cmvj8RDmTYTIDSikLxQ3EeTKcHrvC65Nc4
 ZkgBgHEvo1lIVHnNwf3jveC/O5LupMl2cQuya9jl/7HG6+xnvkQM3ntA4D4gkdsdrHi4b31zZF
 O/Ffy4Sd6WrwGqwmVSfXC559sVl4lDoEhV6BEGfXC25/uIqcWlJWVvpyha45OM4vgBATUvXewE
 AAA==
X-Change-ID: 20261123-b4-cs7542-nand-87997e300079
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mtd@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795794843; l=5336;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=F5YtniD0ib6ly+NKYZzzn7PEEsJXdIDIA6xlLE7enB4=;
 b=RFOtm1GOy3mGhQFdr4ehHVUU8dOFTiPFUQmRBvMoqTktUNPDYu8R8N9P2QNxCJImXyC7UwF6+
 obymGsacxLtDWv/XOSpFOSl1JXQeR21am0HoNu4ggd++ptQ1S/qnN+U
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CS7542 programmed-I/O NAND controller independently of the
platform series and ARCH_CORTINA_ACCESS.

Describe the hardware's two chip selects, 8/16-bit bus and Hamming/BCH
capabilities in the binding. The initial driver supports one connected
8-bit target on either CS, on-host Hamming with 256-byte steps, software
ECC and raw transfers. ECC_NONE is rejected: the core installs split
raw-page callbacks for that mode, which are not safe for this sequencer. It preserves firmware bus timing by retaining
the AXI clock rate. The optional flash reset is acquired without a pulse;
PIO polls completion without claiming the flash IRQ or shared SSP DMA.

Validate generic operation descriptors separately from execution. Use
NAND core page-operation builders in the hardware ECC callbacks instead
of assembling read/program opcodes independently. Preserve the existing
Almond+ Hamming/OOB layout.

Retained v4 validation (the on-host Hamming path is unchanged in v5):
- Full ARM vmlinux/modules builds with the driver =y and =m, without the
  platform series and with COMPILE_TEST=n; software Hamming enabled.
- Binding/example validation and strict source checkpatch.
- Actual NAND core builders and the driver validator: 9815 cases each
  against native and OpenWrt 6.18 headers, GCC and Clang ASan/UBSan.
- Actual hardware-ECC sequencing versus v3: 240 cases per compiler,
  including command/address registers, CS/bank selection, main/ECC/OOB
  ordering and fault cleanup.
- Exact driver compilation with the installed OpenWrt 6.18.64 headers.

The v4 NAND driver booted on Almond+ in a combined OpenWrt
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

New v5 checks: full native ARM vmlinux/modules with COMPILE_TEST=n,
exact Linux 6.18 ARM object compilation with Werror, and 52 actual-source
attach/child-selection cases per compiler under GCC/Clang ASan/UBSan.
These cover a disabled CS0 sibling with enabled CS1 and rejection of
ECC_NONE while retaining software ECC. The board uses a single enabled
CS0 with on-host Hamming; these changes do not alter that tested path.
No new hardware write test or installation is claimed for the v5 delta.

---
Changes in v5:
- Select the available NAND child, including CS1 when CS0 is disabled.
- Reject ECC_NONE; retain software ECC and monolithic raw transfers.
- Check the changed attach and probe paths with actual-source tests.
- Link to v4: https://patch.msgid.link/20261126-b4-cs7542-nand-v4-0-38e488f6f8b1@gmail.com

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
 drivers/mtd/nand/raw/cs752x_nand.c                 | 744 +++++++++++++++++++++
 5 files changed, 854 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-nand-87997e300079

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

