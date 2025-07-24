From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH v5 0/7] riscv: Add support for xmipsexectl
Date: Thu, 24 Jul 2025 17:23:24 +0200
Message-Id: <20250724-p8700-pause-v5-0-a6cbbe1c3412@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOxPgmgC/1XMSw6DIBSF4a2YOy4NIbzsqPswDixchUGFgJI2h
 r2X2lGH/0nOd0DG5DHDrTsgYfHZh7WFuHRg3LQuSLxtDYwyQTnjJGpFKYnTnpFY85C876VGxqE
 9YsLZv05tGFs7n7eQ3ide+Hf9OZKJP6dwQok0ylo1a6GEvLsNzZLCHq8mPGGstX4AeZlCiqoAA
 AA=
X-Change-ID: 20250424-p8700-pause-dcb649968e24
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jonathan Corbet <corbet@lwn.net>
Cc: Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Alexandre Ghiti <alexghiti@rivosinc.com>, 
 Aleksandar Rikalo <arikalo@gmail.com>, 
 Raj Vishwanathan4 <rvishwanathan@mips.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753370612; l=3458;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=yOZQ+GI825AT4Y9e0GYEa/xkkwvxuVvBv4OUaPISJY0=;
 b=8sv1pYiJyHX9Ir2MqQDmuaDGp5IItTyI1Q74xTDUYU67WFrZyJTy0rOANBrhUcUPV1BdZrmL6
 Z7DoXZG8AMmBqkrWvbRDVaHs8M5HJSmaYR2esPqHrzX36LObGdCgI1T
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the xmipsexectl vendor extension.
A new hardware probe key has also been added to allow userspace to probe for MIPS vendor extensions.

Additionally, since the standard Zihintpause PAUSE instruction encoding is not supported on some MIPS CPUs,
an errata was implemented for replacing this instruction with the xmipsexectl MIPS.PAUSE alternative encoding.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
Changes in v5:
- Add MIPS.IHB and MIPS.EHB instructions
- Rebase on alex-for-next
- Address other smaller comments pointed out by Alexandre
- Link to v4: https://lore.kernel.org/r/20250625-p8700-pause-v4-0-6c7dd7f85756@htecgroup.com

This is a continuation of a previous series, which did not implement the full
xmipsexectl vendor extension. The title was updated accordingly.

Changes in v4:
- Add support for the xmipsexectl vendor extension
- Remove the ifdef/else from errata_list.h
- Replace the ifdef/else with a hwprobe call in the userspace code.

Link to v3:
https://lore.kernel.org/linux-riscv/20250129131703.733098-1-arikalo@gmail.com/

---
Aleksa Paunovic (6):
      dt-bindings: riscv: Add xmipsexectl ISA extension description
      riscv: Add xmipsexectl as a vendor extension
      riscv: Add xmipsexectl instructions
      riscv: hwprobe: Add MIPS vendor extension probing
      riscv: hwprobe: Document MIPS xmipsexectl vendor extension
      riscv: Add tools support for xmipsexectl

Djordje Todorovic (1):
      riscv: errata: Fix the PAUSE Opcode for MIPS P8700

 Documentation/arch/riscv/hwprobe.rst               |  9 +++
 .../devicetree/bindings/riscv/extensions.yaml      |  6 ++
 arch/riscv/Kconfig.errata                          | 23 ++++++++
 arch/riscv/Kconfig.vendor                          | 13 +++++
 arch/riscv/errata/Makefile                         |  1 +
 arch/riscv/errata/mips/Makefile                    |  5 ++
 arch/riscv/errata/mips/errata.c                    | 67 ++++++++++++++++++++++
 arch/riscv/include/asm/alternative.h               |  3 +
 arch/riscv/include/asm/cmpxchg.h                   |  3 +-
 arch/riscv/include/asm/errata_list.h               | 13 ++++-
 arch/riscv/include/asm/errata_list_vendors.h       |  5 ++
 arch/riscv/include/asm/hwprobe.h                   |  3 +-
 arch/riscv/include/asm/vdso/processor.h            |  3 +-
 arch/riscv/include/asm/vendor_extensions/mips.h    | 37 ++++++++++++
 .../include/asm/vendor_extensions/mips_hwprobe.h   | 22 +++++++
 arch/riscv/include/asm/vendorid_list.h             |  1 +
 arch/riscv/include/uapi/asm/hwprobe.h              |  1 +
 arch/riscv/include/uapi/asm/vendor/mips.h          |  3 +
 arch/riscv/kernel/alternative.c                    |  5 ++
 arch/riscv/kernel/sys_hwprobe.c                    |  4 ++
 arch/riscv/kernel/vendor_extensions.c              | 10 ++++
 arch/riscv/kernel/vendor_extensions/Makefile       |  2 +
 arch/riscv/kernel/vendor_extensions/mips.c         | 22 +++++++
 arch/riscv/kernel/vendor_extensions/mips_hwprobe.c | 23 ++++++++
 arch/riscv/mm/init.c                               |  1 +
 tools/arch/riscv/include/asm/vdso/processor.h      | 27 +++++----
 26 files changed, 298 insertions(+), 14 deletions(-)
---
base-commit: b6a4bae2f16162876842127d7507dad84e404f8f
change-id: 20250424-p8700-pause-dcb649968e24

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

