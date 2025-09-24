From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH RESEND v6 0/2] riscv: Use GCR.U timer device as clocksource
Date: Wed, 24 Sep 2025 13:10:36 +0200
Message-Id: <20250924-riscv-time-mmio-v6-0-9c6158a14b37@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758712265; l=2047;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=doBgBoI1eDAhaG6OMnM5npExQ5Xq3oY1DJugrOTICDs=;
 b=cGoKWPef+x/OJkYs0CfESXFWfVLvr4WX+Yo6owR4wQKjP0iD42TLYxf1tYO05HzoeQYXSwtF0
 DXSxwdt/bd2Df9BY7kAWrV0PLXuzNvKx6zZxEiTuuxwiSE2do/xWQXQ
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds bindings for the GCR.U timer device and corresponding
driver support. Accessing the memory mapped mtime register in the GCR.U
region should be faster than trapping to M mode each time the timer
needs to be read.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
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

---
Aleksa Paunovic (2):
      dt-bindings: timer: mips,p8700-gcru
      riscv: Allow for riscv-clock to pick up mmio address.

 .../devicetree/bindings/timer/mips,p8700-gcru.yaml | 38 +++++++++++++
 arch/riscv/include/asm/clint.h                     | 26 ---------
 arch/riscv/include/asm/timex.h                     | 63 ++++++++++++----------
 drivers/clocksource/Kconfig                        | 12 +++++
 drivers/clocksource/timer-clint.c                  | 20 ++++---
 drivers/clocksource/timer-riscv.c                  | 34 ++++++++++++
 6 files changed, 128 insertions(+), 65 deletions(-)
---
base-commit: 038d61fd642278bab63ee8ef722c50d10ab01e8f
change-id: 20250424-riscv-time-mmio-5628e0fca8af

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

