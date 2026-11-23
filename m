From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH v4 0/8] Add support for MIPS P8700
Date: Mon, 23 Nov 2026 15:46:55 +0100
Message-Id: <20261123-p8700-dts-v4-0-60bb7bf8a7a1@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN9RBGsC/23MQQ6CMBCF4auYrq3pTAsFV97DuIAyhS4E0mKjI
 dzdgokhxuWbzPfPLJB3FNj5MDNP0QU39Gmo44GZrupb4q5Jm6HAXEjM+FhoIXgzBa5AF4UVoBA
 1S/+jJ+ueW+t6S7tzYRr8a0tHWK+fSglqV4nABZeYawuKakNw6SYyrR8e48kMd7aWIn41gJB7j
 auuTNao0qKR+p+WOw35XsukacW1bkiW9lcvy/IGBU5OKSIBAAA=
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
 Palmer Dabbelt <palmer@sifive.com>, Joel Stanley <joel@jms.id.au>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795445243; l=4767;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=fk2JShQCzrA8OtTZu8VbzvejSAGg+O0BzIRRDTpGEr4=;
 b=nsH9cdBjPokP8DnwyoNqo9owmGhVw/iboBNhywcntNuIYDvUIDmlbhVx9xQUIzPdDb1F1lDyn
 7nDWGmXN+qICLJRh0O0/x4oizwIn9UW6N+lXlFKeckKNa6vve4Mq9Ai
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

I tested this series both on QEMU and a Boston board
configured with a single P8700 CPU,
after applying the necessary U-Boot changes.
We are planning on upstreaming these as well.

Following the discussion in [2], I decided to drop the 'gf' prefix for all compatibles
and to rework the aclint-mtimer binding.

Links:
[1] https://mips.com/wp-content/uploads/2025/11/P8700-F_Programmers_Reference_Manual-TM.pdf
[2] https://lore.kernel.org/linux-riscv/20261109051050.105623-5-joel@jms.id.au/
[3] https://training.mips.com/cps_mips/Examples/MD00901_Boot-MIPS_Example_Boot_Code_for_MIPS_Cores.pdf
[4] https://lore.kernel.org/all/20261026-lrsc-only-v3-0-ec29c8190fb1@mobileye.com/

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
Changes in v4:
- Add git tree link to the MAINTAINERS entry.
- Require the names of mtimer registers to be 'mtime' and 'mtimecmp', as suggested by Sashiko.
  Update the commit message to reflect the reasoning for changes in v3, suggested by Conor.
- Link to v3: https://lore.kernel.org/r/20261116-p8700-dts-v3-0-ec5d4b7de39f@htecgroup.com

Changes in v3:
- Drop the 'gf' vendor prefix patch. The prefix isn't used anywhere.
- Replace 'gf,mips-p8700-*' compatibles with 'mips,p8700-*'
  to match those already present in OpenSBI.
  Other compatibles are also renamed for consistency.
  Match the directory structure and binding names,
  by replacing 'gf' with 'mips' everywhere.
- Add a MAINTAINERS entry.
- Change the `aclint-mtimer` binding, reversing the decision made in v2
  and putting 'mtime' first when both 'mtime' and 'mtimecmp' are present.
- Link to v2: https://lore.kernel.org/r/20261103-p8700-dts-v2-0-3ac5d49f2c37@htecgroup.com

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
      dt-bindings: riscv: cpus: add mips,p8700
      dt-bindings: riscv: Add MIPS Boston board compatible
      dt-bindings: interrupt-controller: Add MIPS P8700 APLIC
      dt-bindings: interrupt-controller: Add MIPS P8700 ACLINT MSWI
      dt-bindings: timer: Add MIPS P8700 ACLINT MTIMER
      riscv: dts: mips: Initial support for the P8700 Boston board
      MAINTAINERS: Add entry for MIPS RISC-V SoC support
      riscv: defconfig: Enable MIPS SoCs

 .../bindings/interrupt-controller/riscv,aplic.yaml |   1 +
 .../thead,c900-aclint-mswi.yaml                    |  11 ++
 Documentation/devicetree/bindings/riscv/cpus.yaml  |   1 +
 Documentation/devicetree/bindings/riscv/mips.yaml  |  33 +++++
 .../bindings/timer/thead,c900-aclint-mtimer.yaml   |  39 ++++++
 MAINTAINERS                                        |   8 ++
 arch/riscv/Kconfig.socs                            |   6 +
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/mips/Makefile                  |   2 +
 arch/riscv/boot/dts/mips/p8700-boston.dts          | 135 +++++++++++++++++++++
 arch/riscv/boot/dts/mips/p8700.dtsi                |  82 +++++++++++++
 arch/riscv/configs/defconfig                       |   1 +
 12 files changed, 320 insertions(+)
---
base-commit: fd73f4a6659897191fa0d40695fe370925dd3780
change-id: 20260325-p8700-dts-41788f014227

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

