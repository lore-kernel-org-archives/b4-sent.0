From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH v2 0/8] Add support for MIPS P8700
Date: Tue, 03 Nov 2026 16:11:24 +0100
Message-Id: <20261103-p8700-dts-v2-0-3ac5d49f2c37@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJz56WoC/03MQQ6CMBCF4auQWVvTGSpFVt7DsNAypV1ISYtEQ
 3p3K25c/i8v3waJo+cEXbVB5NUnH6YSdKjAuNs0svBDaSBJjazpJOZWSymGJQmFum2tREWkofz
 nyNa/duval3Y+LSG+d3rF7/pTzqj+lBWFFDU12qLiu2G8uIXNGMNzPprwgD7n/AH05L2cpgAAA
 A==
X-Change-ID: 20260325-p8700-dts-41788f014227
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Anup Patel <anup@brainfault.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Inochi Amaoto <inochiama@outlook.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Conor Dooley <conor@kernel.org>, linux-riscv@lists.infradead.org, 
 Vladimir Kondratiev <vladimir.kondratiev@mobileye.com>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793718695; l=3907;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=zHYiuOrAOGUKb3zk94xINXfL6OoQmBspjmotb9xqkoU=;
 b=33gipfFB6OzQenMAHjINnWTFCT/xdttEHnqLGCLAJiRQNhETw4JLG2O0GHJThKzb8M3j5YRLT
 oCK/su/6u43B8QEX7nQDKqC3jwkwpElqvZbIKl+DAVwNwb/gG5Ptwhp
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MIPS P8700 is a multi-core RISC-V microprocessor system, supporting
both single-cluster and multi-cluster configurations. [1]
This series adds full description of the platform,
including the Boston FPGA board configured with a P8700 bitfile.

The P8700 cores support the RV64GCZba_Zbb (G = IMAFD) Standard ISA,
with a caveat: the A extension is only partially supported, and all ZAAMO
extension instructions are emulated on the SBI level. The device tree
intentionally does not reflect this fact. Vladimir Kondratiev's series
improves performance by directly substituting AMO instructions with LR/SC. [4]
The two patchsets do not depend on one another.

The board itself is the same board as 'img,boston', configured with a different
bitfile [3]. The Boston board has been supported since commit 6e62a888029b
("MIPS: generic: Support MIPS Boston development boards") (thanks to Maciej for finding the ref).

GlobalFoundries has acquired MIPS [2] and the vendor prefix
for all newly added MIPS RISC-V hardware reflects that fact.

I tested this series both on QEMU and a Boston board
configured with a single P8700 CPU,
after applying the necessary U-Boot and OpenSBI changes
to match the 'compatible' strings and the changed MTIMER register order.
We are planning to upstream these as well.

Links:
[1] https://mips.com/wp-content/uploads/2025/11/P8700-F_Programmers_Reference_Manual-TM.pdf
[2] https://gf.com/news-and-events/news/globalfoundries-completes-acquisition-of-mips/
[3] https://training.mips.com/cps_mips/Examples/MD00901_Boot-MIPS_Example_Boot_Code_for_MIPS_Cores.pdf
[4] https://lore.kernel.org/all/20261026-lrsc-only-v3-0-ec29c8190fb1@mobileye.com/

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
Changes in v2:
- Patch 1: Replace "MIPS Technology" with "MIPS Technologies".
- Patch 3: Name the FPGA used and add the versioned bitfile compatible.
- Patch 5: Drop hart indexes from MSWI.
- Patch 6: Swap mtimecmp and mtime, require reg-names both for mtime and mtimecmp on P8700.
- Original patch 7: Dropped.
- Patch 7 (previously 8): Remove additional harts that are not
  present in the bitfile I have. Reflect changes made in patches 3, 5 and 6.
  Remove riscv,cbom-block-size. Drop undocumented compatibles. Other minor changes.
- Link to v1: https://lore.kernel.org/r/20260914-p8700-dts-v1-0-3267f14ebce1@htecgroup.com

---
Aleksa Paunovic (8):
      dt-bindings: vendor-prefixes: Add GlobalFoundries, Inc.
      dt-bindings: riscv: cpus: add gf,mips-p8700
      dt-bindings: riscv: Add MIPS Boston board compatible
      dt-bindings: interrupt-controller: Add MIPS P8700 APLIC
      dt-bindings: interrupt-controller: Add MIPS P8700 ACLINT MSWI
      dt-bindings: timer: Add MIPS P8700 ACLINT MTIMER
      riscv: dts: gf: Initial support for the P8700 Boston board
      riscv: defconfig: Enable GF SoCs

 .../bindings/interrupt-controller/riscv,aplic.yaml |   1 +
 .../thead,c900-aclint-mswi.yaml                    |  11 ++
 Documentation/devicetree/bindings/riscv/cpus.yaml  |   1 +
 Documentation/devicetree/bindings/riscv/gf.yaml    |  33 +++++
 .../bindings/timer/thead,c900-aclint-mtimer.yaml   |  35 ++++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   4 +-
 arch/riscv/Kconfig.socs                            |   6 +
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/gf/Makefile                    |   2 +
 arch/riscv/boot/dts/gf/p8700-boston.dts            | 135 +++++++++++++++++++++
 arch/riscv/boot/dts/gf/p8700.dtsi                  |  82 +++++++++++++
 arch/riscv/configs/defconfig                       |   1 +
 12 files changed, 311 insertions(+), 1 deletion(-)
---
base-commit: fd73f4a6659897191fa0d40695fe370925dd3780
change-id: 20260325-p8700-dts-41788f014227

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

