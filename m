From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH v5 0/2] riscv: Use GCR.U timer device as clocksource
Date: Fri, 11 Jul 2025 23:56:44 +0200
Message-Id: <20250711-riscv-time-mmio-v5-0-9ed1f825ad5e@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJyIcWgC/2WNQQ6CMBBFr0K6dkydtARdeQ/CAocpzKKUtNhoC
 He34tLle8l/f1OJo3BSt2pTkbMkCXMBe6oUTf08MshQWKFGqw0aiJIowyqewXsJYGtsWDvqm96
 psloiO3kdxbYrPElaQ3wfB9l87a9lL/+tbEADPTQ5vCIOdX2fVqYxhudypuBVt+/7BzH0MY6yA
 AAA
X-Change-ID: 20250424-riscv-time-mmio-5628e0fca8af
To: Daniel Lezcano <daniel.lezcano@linaro.org>, 
 Thomas Gleixner <tglx@linutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752271040; l=1798;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=rKK6/zAeDGlf2Rcw+XgRGzGg1wLNDrZiOXO05uwH78I=;
 b=KytOxScst8FlcaqhCNUXLNgl4U+YRyv7Yo59CwjWeu9RGKO7KU14DknmC2ThSZqyiN+EJWQ1u
 i925hQY2QoLCIseXEBHReLzdPoZyna1zQlpJcjdIQHTIeO/BV4wy6H7
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds bindings for the GCR.U timer device and corresponding
driver support. Accessing the memory mapped mtime register in the GCR.U
region should be faster than trapping to M mode each time the timer
needs to be read.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
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

---
Aleksa Paunovic (2):
      dt-bindings: timer: mti,gcru
      riscv: Allow for riscv-clock to pick up mmio address.

 .../devicetree/bindings/timer/mti,gcru.yaml        | 38 +++++++++++++
 arch/riscv/include/asm/clint.h                     | 26 ---------
 arch/riscv/include/asm/timex.h                     | 63 ++++++++++++----------
 drivers/clocksource/Kconfig                        | 12 +++++
 drivers/clocksource/timer-clint.c                  | 20 ++++---
 drivers/clocksource/timer-riscv.c                  | 34 ++++++++++++
 6 files changed, 128 insertions(+), 65 deletions(-)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250424-riscv-time-mmio-5628e0fca8af

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

