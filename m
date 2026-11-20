From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 20 Nov 2026 05:38:06 +0000
Subject: [PATCH 2/2] ALSA: fireworks: Rearm the transaction after a bus
 reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-firewire-busreset-v1-2-8bb9079a2984@gmail.com>
References: <20261120-firewire-busreset-v1-0-8bb9079a2984@gmail.com>
In-Reply-To: <20261120-firewire-busreset-v1-0-8bb9079a2984@gmail.com>
To: clemens@ladisch.de, o-takashi@sakamocchi.jp, tiwai@suse.com
Cc: stefanr@s5r6.in-berlin.de, linux-sound@vger.kernel.org, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795153085; l=1609;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=1Y5tLKaRBeTaHsrbFAyk3KOEWMVkXW1Qflif+BgawNU=;
 b=jfZH8RUBvwraViT8Is2/7Gi8yarnl9HNAqUbWPcQSzB3Bty7B0Xq67oE/zAQRKUHbPmIBsdIE
 9y9YKoNEzXYBaW4ox60Dpfw/3UCwnmwqwrGkQNv3hSpokJOeUSp4Zqr
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

snd_efw_transaction_run() has the same problem as fcp_avc_transaction():
after snd_efw_transaction_bus_reset() moves the transaction to
STATE_BUS_RESET, the loop sleeps and resends the command but leaves the
state as it is. The response handler only completes a transaction in
STATE_PENDING, and wait_event_timeout() returns at once on the stale
state, so the command is resent every ERROR_DELAY_MS without counting
tries and the caller never returns unless sending fails.

Set the state back to STATE_PENDING before resending.

Found with a static analysis tool and checked by hand.

Fixes: bde8a8f23bbe ("ALSA: fireworks: Add transaction and some commands")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 sound/firewire/fireworks/fireworks_transaction.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/firewire/fireworks/fireworks_transaction.c b/sound/firewire/fireworks/fireworks_transaction.c
index 5c859773fe06..57aef570ac2d 100644
--- a/sound/firewire/fireworks/fireworks_transaction.c
+++ b/sound/firewire/fireworks/fireworks_transaction.c
@@ -100,6 +100,8 @@ int snd_efw_transaction_run(struct fw_unit *unit,
 			break;
 		} else if (t.state == STATE_BUS_RESET) {
 			msleep(ERROR_DELAY_MS);
+			/* resend the command and wait for its response again */
+			t.state = STATE_PENDING;
 		} else if (++tries >= ERROR_RETRIES) {
 			dev_err(&t.unit->device, "EFW transaction timed out\n");
 			ret = -EIO;

-- 
2.34.1

