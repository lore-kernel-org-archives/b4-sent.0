From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH v8 0/3] riscv: Use GCR.U timer device as clocksource
Date: Wed, 10 Jun 2026 10:22:12 +0200
Message-Id: <20260610-riscv-time-mmio-v8-0-a865206675c6@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALQeKWoC/23OwW7DIAyA4VepOJfKeEBgp73HtAMF03BIqSBDr
 aq8e2mnqYfk+FvyZ99ZpZKoss/dnRVqqaZ87mH2O+ZHdz4RT6E3Q0AFEiUvqfrG5zQRn6aUudJ
 oCKJ3xkXWty6FYrq+xO+f3mOqcy6314Emn9M/S4m11SQH7o/gI1rEoPXXOJM/lfx7Ofg8safX1
 NsYhFgbqhuWgogGlQuKtgz9NgzotaG7gSECGRTWWrNlDP+Gho+tP4ZugNBGKgfRwMpYluUBRAt
 5b34BAAA=
X-Change-ID: 20250424-riscv-time-mmio-5628e0fca8af
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Paul Walmsley <pjw@kernel.org>, 
 John Stultz <jstultz@google.com>, Stephen Boyd <sboyd@kernel.org>, 
 Vivian Wang <wangruikang@iscas.ac.cn>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Chao-ying Fu <cfu@mips.com>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781079735; l=3233;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=y/8iwhBGrz+460yP9z42mHYiw/ZuWpDLnM1e8u/ZHbQ=;
 b=WcRCMW6dQrxGWDk0yKwSrjsjywVVmU2dsOM9xJyjDNcgC1qzPdcrhNmK5Xxlfl3WsvMUbhn04
 d3t4MiDkJGYAdDNXkgyIK9cGLK/xIGOEzpfLlGyrHzLrRYJjLdnSL3H
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds bindings for the GCR.U timer device and corresponding
driver support. Accessing the memory mapped shadow of the mtime register
in the GCR.U region should be faster
than trapping to M mode each time the timer needs to be read.
The timer device does not implement any interrupts, therefore the
timer-riscv clockevent implementation should suffice.

We tested the patchset both on QEMU and the Boston board with the P8700 bitfile:
- v7, v8 testing:
  - Coremark and timer kselftests on QEMU emulating an 8 core CPU
  - Coremark and timer kselftests on the Boston board with a single core CPU.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Signed-off-by: Djordje Todorovic <djordje.todorovic@htecgroup.com>
Signed-off-by: Chao-ying Fu <cfu@mips.com>
---
Changes in v8:
- Make the 64 bit timer mmio reads and the main timer driver depend on CONFIG_64BIT
- Add timer_of_cleanup to the driver code
- Link to v7: https://lore.kernel.org/r/20260311-riscv-time-mmio-v7-0-016845a0f808@htecgroup.com

Changes in v7:
- Replace the previous implementation with a new timer driver for mips,p8700-gcru
- Add a patch for 64bit reads for timer mmio
- Link to v6: https://lore.kernel.org/r/20250806-riscv-time-mmio-v6-0-2df0e8219998@htecgroup.com

Changes in v6:
- Rename mti,gcru to mips,p8700-gcru
- Link to v5: https://lore.kernel.org/r/20250711-riscv-time-mmio-v5-0-9ed1f825ad5e@htecgroup.com

Changes in v5:
- Fixed build issues on 32-bit RISC-V and sparse warnings
- Remove clint_time_val and clint.h, replace with riscv_time_val
- Depend on RISCV_TIMER in Kconfig

Changes in v4:
- Remove "select" from mti,gcru.yaml.
- Refactor the driver to use function pointers instead of static keys.

Previous versions:
v1: https://lore.kernel.org/lkml/20241227150056.191794-1-arikalo@gmail.com/#t
v2: https://lore.kernel.org/linux-riscv/20250409143816.15802-1-aleksa.paunovic@htecgroup.com/
v3: https://lore.kernel.org/linux-riscv/DU0PR09MB61968695A2A3146EE83B7708F6BA2@DU0PR09MB6196.eurprd09.prod.outlook.com/
v4: https://lore.kernel.org/r/20250514-riscv-time-mmio-v4-0-cb0cf2922d66@htecgroup.com
v5: https://lore.kernel.org/r/20250711-riscv-time-mmio-v5-0-9ed1f825ad5e@htecgroup.com
v6: https://lore.kernel.org/r/20250806-riscv-time-mmio-v6-0-2df0e8219998@htecgroup.com
v7: https://lore.kernel.org/r/20260311-riscv-time-mmio-v7-0-016845a0f808@htecgroup.com

---
Aleksa Paunovic (3):
      dt-bindings: timer: mips,p8700-gcru
      riscv: clocksource: Add readq options to clocksource mmio
      riscv: clocksource: Add p8700-gcru driver

 .../devicetree/bindings/timer/mips,p8700-gcru.yaml | 38 +++++++++++++++++
 drivers/clocksource/Kconfig                        |  9 +++++
 drivers/clocksource/Makefile                       |  1 +
 drivers/clocksource/mmio.c                         | 14 +++++++
 drivers/clocksource/timer-p8700.c                  | 47 ++++++++++++++++++++++
 include/linux/clocksource.h                        |  4 ++
 6 files changed, 113 insertions(+)
---
base-commit: ac3fd01e4c1efce8f2c054cdeb2ddd2fc0fb150d
change-id: 20250424-riscv-time-mmio-5628e0fca8af

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

