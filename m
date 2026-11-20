From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 20 Nov 2026 05:38:05 +0000
Subject: [PATCH 1/2] ALSA: firewire-lib: Rearm the FCP transaction after a
 bus reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-firewire-busreset-v1-1-8bb9079a2984@gmail.com>
References: <20261120-firewire-busreset-v1-0-8bb9079a2984@gmail.com>
In-Reply-To: <20261120-firewire-busreset-v1-0-8bb9079a2984@gmail.com>
To: clemens@ladisch.de, o-takashi@sakamocchi.jp, tiwai@suse.com
Cc: stefanr@s5r6.in-berlin.de, linux-sound@vger.kernel.org, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795153085; l=1810;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=EE0vJ5UFqV3N6FNYlkeZNWSM/T/1oLRQlOmSvnwwh9g=;
 b=s2EAJox6FjbrpFgp6SBB/2R+YVmgxiG6MCYUTB3nsjnSxeNnaRiDs0ZY7Mr46dbd67uhBexKL
 K5eKsEuRjngCMFmpPJObtvnSx28t/G0b5okxp6rBwJPJV4iEXd1Ls76
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When a bus reset happens while fcp_avc_transaction() waits for a
response, fcp_bus_reset() moves the transaction to STATE_BUS_RESET and
wakes the waiter, which sleeps and then sends the command again.
Nothing sets the state back to STATE_PENDING, though:

	wait_event_timeout(t.wait, t.state != STATE_PENDING, ...);
	...
	} else if (t.state == STATE_BUS_RESET) {
		msleep(ERROR_DELAY_MS);
	}

fcp_response() only accepts a response for a transaction in
STATE_PENDING, so the response to the resent command is ignored, and
wait_event_timeout() returns at once because the state is still
STATE_BUS_RESET. The loop then resends the command every
ERROR_DELAY_MS without counting tries, and the caller never returns
unless sending the command itself fails.

Set the state back to STATE_PENDING before resending, as the
STATE_DEFERRED branch already does.

Found with a static analysis tool and checked by hand.

Fixes: 31ef9134eb52 ("ALSA: add LaCie FireWire Speakers/Griffin FireWave Surround driver")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 sound/firewire/fcp.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/firewire/fcp.c b/sound/firewire/fcp.c
index e60bfd0ee4ac..d733f6123baa 100644
--- a/sound/firewire/fcp.c
+++ b/sound/firewire/fcp.c
@@ -273,6 +273,8 @@ int fcp_avc_transaction(struct fw_unit *unit,
 			break;
 		} else if (t.state == STATE_BUS_RESET) {
 			msleep(ERROR_DELAY_MS);
+			/* resend the command and wait for its response again */
+			t.state = STATE_PENDING;
 		} else if (++tries >= ERROR_RETRIES) {
 			dev_err(&t.unit->device, "FCP command timed out\n");
 			ret = -EIO;

-- 
2.34.1

