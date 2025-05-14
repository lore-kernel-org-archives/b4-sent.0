From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Subject: [PATCH v4 0/2] Use GCR.U timer device as clocksource
Date: Wed, 14 May 2025 10:51:49 +0200
Message-Id: <20250514-riscv-time-mmio-v4-0-cb0cf2922d66@htecgroup.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKVZJGgC/x3MQQqAIBBA0avIrBsQ0ZCuEi3ExpqFGhoShHdPW
 r7F/y9UKkwVFvFCocaVcxrQkwB/unQQ8j4MSiojtdJYuPqGN0fCGDmjmZUlGbyzLsCorkKBn/+
 4br1/N1+qi2EAAAA=
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
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747212741; l=1393;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=pn79s5/J/P9TNe+3hLy3s/qDtoOXGxNKcDbvTKLxHq0=;
 b=rlPq6swwSQfvouul8tW+SJQHbhgJ9bLJXKSNximZEzgFJegjutl9e61P7ng8+xa0j9c7BERNl
 peYI8pd6S8tAMlHpGC/INhUOvEzV/JOrTCoHCBvvxYC+8x1rhWP5QuQ
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds bindings for the GCR.U timer device and corresponding
driver support. Accessing the memory mapped mtime register in the GCR.U
region should be faster than trapping to M mode each time the timer
needs to be read.

Changes in v4:
- Remove "select" from mti,gcru.yaml.
- Refactor the driver to use function pointers instead of static keys.

Previous versions:
v1: https://lore.kernel.org/lkml/20241227150056.191794-1-arikalo@gmail.com/#t
v2: https://lore.kernel.org/linux-riscv/20250409143816.15802-1-aleksa.paunovic@htecgroup.com/
v3: https://lore.kernel.org/linux-riscv/DU0PR09MB61968695A2A3146EE83B7708F6BA2@DU0PR09MB6196.eurprd09.prod.outlook.com/

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
Aleksa Paunovic (2):
      dt-bindings: timer: mti,gcru
      Allow for riscv-clock to pick up mmio address.

 .../devicetree/bindings/timer/mti,gcru.yaml        | 38 ++++++++++++++
 arch/riscv/include/asm/timex.h                     | 48 ++++++-----------
 drivers/clocksource/Kconfig                        | 12 +++++
 drivers/clocksource/timer-riscv.c                  | 61 ++++++++++++++++++++++
 4 files changed, 126 insertions(+), 33 deletions(-)
---
base-commit: 9c32cda43eb78f78c73aee4aa344b777714e259b
change-id: 20250424-riscv-time-mmio-5628e0fca8af

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

