From: Andrei Lalaev <andrei.lalaev@anton-paar.com>
Date: Wed, 20 Aug 2025 10:47:12 +0200
Subject: [PATCH] leds: leds-lp55xx: use correct address for memory
 programming
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250820-lp5562-prog-mem-address-v1-1-8569647fa71d@anton-paar.com>
X-B4-Tracking: v=1; b=H4sIAI+LpWgC/x3MwQqDMAyA4VeRnA10qR3iqwwPnU01MLUkIIPiu
 6/s+B3+v4KxChtMXQXlS0zOo+HRd7Bs8VgZJTUDOQpuJIefEsKTsOi54s47xpSUzTBn7+NC4c0
 0QKuLcpbv//ya7/sHE2NruWkAAAA=
X-Change-ID: 20250820-lp5562-prog-mem-address-ff33ac25be24
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Christian Marangi <ansuelsmth@gmail.com>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andrei Lalaev <andrei.lalaev@anton-paar.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755679639; l=2080;
 i=andrei.lalaev@anton-paar.com; s=20250820; h=from:subject:message-id;
 bh=8WvWq+dM1/5loxJ8nu3rUh9bYc0hws/+X0jjGLoaSrc=;
 b=aBLz/tpvJEzPDaAHWI4BCDHTmY+tWTlHTu4HCifxtdidOgtoNyVPGWJ5kt2KhMbk+Dpl/2jMA
 pcqqBTyEw1SDiAjK7ruwhq6h9+Sfsf/xUEwd5n2fV/29RuXsZPp45xb
X-Developer-Key: i=andrei.lalaev@anton-paar.com; a=ed25519;
 pk=728nZXw7ILalhZmxQ0hPJ77AKRvsdNkq+v6XdryA5fM=
X-Endpoint-Received: by B4 Relay for andrei.lalaev@anton-paar.com/20250820 with auth_id=496
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Memory programming doesn't work for devices without page support.
For example, LP5562 has 3 engines but doesn't support pages,
the start address is changed depending on engine number.
According to datasheet [1], the PROG MEM register addresses for each
engine are as follows:

  Engine 1: 0x10
  Engine 2: 0x30
  Engine 3: 0x50

However, the current implementation incorrectly calculates the address
of PROG MEM register using the engine index starting from 1:

  prog_mem_base = 0x10
  LP55xx_BYTES_PER_PAGE = 0x20

  Engine 1: 0x10 + 0x20 * 1 = 0x30
  Engine 2: 0x10 + 0x20 * 2 = 0x50
  Engine 3: 0x10 + 0x20 * 3 = 0x70

This results in writing to the wrong engine memory, causing pattern
programming to fail.

To correct it, the engine index should be decreased:
  Engine 1: 0x10 + 0x20 * 0 = 0x10
  Engine 2: 0x10 + 0x20 * 1 = 0x30
  Engine 3: 0x10 + 0x20 * 2 = 0x50

1 - https://www.ti.com/lit/ds/symlink/lp5562.pdf

Fixes: 31379a57cf2f ("leds: leds-lp55xx: Generalize update_program_memory function")
Signed-off-by: Andrei Lalaev <andrei.lalaev@anton-paar.com>
---
 drivers/leds/leds-lp55xx-common.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/leds/leds-lp55xx-common.c b/drivers/leds/leds-lp55xx-common.c
index e71456a56ab8dae56988f50edd267e8e55090df8..fd447eb7eb15e243f1c470085f7780a8da866286 100644
--- a/drivers/leds/leds-lp55xx-common.c
+++ b/drivers/leds/leds-lp55xx-common.c
@@ -212,7 +212,7 @@ int lp55xx_update_program_memory(struct lp55xx_chip *chip,
 	 * For LED chip that support page, PAGE is already set in load_engine.
 	 */
 	if (!cfg->pages_per_engine)
-		start_addr += LP55xx_BYTES_PER_PAGE * idx;
+		start_addr += LP55xx_BYTES_PER_PAGE * (idx - 1);
 
 	for (page = 0; page < program_length / LP55xx_BYTES_PER_PAGE; page++) {
 		/* Write to the next page each 32 bytes (if supported) */

---
base-commit: b19a97d57c15643494ac8bfaaa35e3ee472d41da
change-id: 20250820-lp5562-prog-mem-address-ff33ac25be24

Best regards,
-- 
Andrei Lalaev <andrei.lalaev@anton-paar.com>

