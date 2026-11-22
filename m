From: Suyuan Wang <shyckless@gmail.com>
Date: Sun, 22 Nov 2026 13:46:29 +0000
Subject: [PATCH v2 1/2] ALSA: firewire-lib: Abort the FCP transaction on a
 bus reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-firewire-busreset-v2-1-e104d785c8a1@gmail.com>
References: <20261122-firewire-busreset-v2-0-e104d785c8a1@gmail.com>
In-Reply-To: <20261122-firewire-busreset-v2-0-e104d785c8a1@gmail.com>
To: o-takashi@sakamocchi.jp, clemens@ladisch.de, tiwai@suse.com
Cc: stefanr@s5r6.in-berlin.de, linux-sound@vger.kernel.org, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795355188; l=2101;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=6CqPPE3mEanKHilmp+S+EGLzRo0PnbexFfGZIxBreE4=;
 b=Yj/RgLnO8Z/dSCfWK46K0CN3liyIYd0tkQMUJh9vZHV/VYjNizrTQ+hZtZvNPJK3QUlAw0jaE
 aHWky6y0QI1DH6BBqNoQeCFKQNw9+SIXN76/86yDZ7iLoUCNIXIw3Dr
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When fcp_bus_reset() marks a transaction as STATE_BUS_RESET,
fcp_avc_transaction() sleeps and resends the command, but leaves the
state as it is. The response to the resent command is then ignored, and
the next wait returns at once, so the loop keeps resending the command
without a retry limit until sending fails.

The AV/C Digital Interface Command Set General Specification 4.2 says
that a target which detects a bus reset discards any AV/C transaction
in progress without returning a response. So instead of resending, end
the transaction on a bus reset and return -EAGAIN, so that the caller
can start the sequence again. ERROR_DELAY_MS and <linux/delay.h> have no
users left after this, so drop them.

Found with a static analysis tool and checked by hand.

Suggested-by: Takashi Sakamoto <o-takashi@sakamocchi.jp>
Fixes: 31ef9134eb52 ("ALSA: add LaCie FireWire Speakers/Griffin FireWave Surround driver")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 sound/firewire/fcp.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/sound/firewire/fcp.c b/sound/firewire/fcp.c
index e60bfd0ee4ac..b8e7e2c90791 100644
--- a/sound/firewire/fcp.c
+++ b/sound/firewire/fcp.c
@@ -14,7 +14,6 @@
 #include <linux/sched.h>
 #include <linux/spinlock.h>
 #include <linux/wait.h>
-#include <linux/delay.h>
 #include "fcp.h"
 #include "lib.h"
 #include "amdtp-stream.h"
@@ -22,7 +21,6 @@
 #define CTS_AVC 0x00
 
 #define ERROR_RETRIES	3
-#define ERROR_DELAY_MS	5
 #define FCP_TIMEOUT_MS	125
 
 int avc_general_set_sig_fmt(struct fw_unit *unit, unsigned int rate,
@@ -272,7 +270,8 @@ int fcp_avc_transaction(struct fw_unit *unit,
 			ret = t.response_size;
 			break;
 		} else if (t.state == STATE_BUS_RESET) {
-			msleep(ERROR_DELAY_MS);
+			ret = -EAGAIN;
+			break;
 		} else if (++tries >= ERROR_RETRIES) {
 			dev_err(&t.unit->device, "FCP command timed out\n");
 			ret = -EIO;

-- 
2.34.1

