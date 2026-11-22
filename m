From: Suyuan Wang <shyckless@gmail.com>
Date: Sun, 22 Nov 2026 13:46:30 +0000
Subject: [PATCH v2 2/2] ALSA: fireworks: Abort the transaction on a bus
 reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-firewire-busreset-v2-2-e104d785c8a1@gmail.com>
References: <20261122-firewire-busreset-v2-0-e104d785c8a1@gmail.com>
In-Reply-To: <20261122-firewire-busreset-v2-0-e104d785c8a1@gmail.com>
To: o-takashi@sakamocchi.jp, clemens@ladisch.de, tiwai@suse.com
Cc: stefanr@s5r6.in-berlin.de, linux-sound@vger.kernel.org, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795355188; l=1920;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=fhg9NDjaNT8GJA64KhkdJLd88zbmeEobh1mF6AYpWhI=;
 b=lUwJGdBidPNerzLa0yBkLF9tU6IAej1hLyHVFB831ArGHR82Z/pk553D0kCvPm9jsmArt+bWc
 HzaBwnmNi9VC8uG1ryjSTNMmJ+YwujOqW9kBeRvgrW/4L34hDLl3/O5
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When snd_efw_transaction_bus_reset() marks a transaction as
STATE_BUS_RESET, snd_efw_transaction_run() sleeps and resends the
command, but leaves the state as it is. The response to the resent
command is then ignored, and the next wait returns at once, so the loop
keeps resending the command without a retry limit until sending fails.

Fireworks devices also accept AV/C commands, and the AV/C general
specification says that a bus reset discards any transaction in
progress. Do the same as for FCP: end the transaction on a bus reset and
return -EAGAIN. ERROR_DELAY_MS has no users left, so drop it.

Found with a static analysis tool and checked by hand.

Suggested-by: Takashi Sakamoto <o-takashi@sakamocchi.jp>
Fixes: bde8a8f23bbe ("ALSA: fireworks: Add transaction and some commands")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 sound/firewire/fireworks/fireworks_transaction.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/sound/firewire/fireworks/fireworks_transaction.c b/sound/firewire/fireworks/fireworks_transaction.c
index 5c859773fe06..bb9ab8ed52b5 100644
--- a/sound/firewire/fireworks/fireworks_transaction.c
+++ b/sound/firewire/fireworks/fireworks_transaction.c
@@ -34,7 +34,6 @@
 #define MEMORY_SPACE_EFW_RESPONSE	0xecc080000000ULL
 
 #define ERROR_RETRIES 3
-#define ERROR_DELAY_MS 5
 #define EFC_TIMEOUT_MS 125
 
 static DEFINE_SPINLOCK(instances_lock);
@@ -99,7 +98,8 @@ int snd_efw_transaction_run(struct fw_unit *unit,
 			ret = t.size;
 			break;
 		} else if (t.state == STATE_BUS_RESET) {
-			msleep(ERROR_DELAY_MS);
+			ret = -EAGAIN;
+			break;
 		} else if (++tries >= ERROR_RETRIES) {
 			dev_err(&t.unit->device, "EFW transaction timed out\n");
 			ret = -EIO;

-- 
2.34.1

