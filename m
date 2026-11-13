From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 13 Nov 2026 20:14:20 +0100
Subject: [PATCH RFC wireless-next 1/2] wifi: wlcore: Allow lower drivers
 without firmware statistics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-upstream-wl18xx-fw-stats-v1-1-cbdf50739185@tsv-stahl-riesa.de>
References: <20261113-upstream-wl18xx-fw-stats-v1-0-cbdf50739185@tsv-stahl-riesa.de>
In-Reply-To: <20261113-upstream-wl18xx-fw-stats-v1-0-cbdf50739185@tsv-stahl-riesa.de>
To: linux-wireless@vger.kernel.org
Cc: Johannes Berg <johannes@sipsolutions.net>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794597277; l=2225;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=DLPaddbG/sGe9ubZujK/V4mAu1TXJj8UjY81Qo5V66M=;
 b=4e8PvcIh0xJRjtVB3WR0qKh2zYw/1nx9wl1QhH4bTAYCqbJMXLHA36J21KFsEZxJLVd1v5yeU
 PsfVm7HfQLFBWcsUL1s0ZPkvTyIc/OgzAxL8bwTQ1l2MS6HE7MdJoU4
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wl1271_debugfs_init() always allocates wl->stats.fw_stats and exposes
it as fw_stats_raw, and the lower drivers query the firmware for it
with ACX_STATISTICS. A lower driver that cannot use ACX_STATISTICS
safely has no way to opt out.

Treat a fw_stats_len of 0 as "no firmware statistics": don't allocate
the buffer, don't create fw_stats_raw, and never send ACX_STATISTICS
from wl1271_debugfs_update_stats(). wl1271_debugfs_reset() and
wl1271_debugfs_exit() already cope with a NULL buffer.

No functional change for wl12xx and wl18xx, which both set
fw_stats_len.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/net/wireless/ti/wlcore/debugfs.c | 18 +++++++++++++-----
 1 file changed, 13 insertions(+), 5 deletions(-)

diff --git a/drivers/net/wireless/ti/wlcore/debugfs.c b/drivers/net/wireless/ti/wlcore/debugfs.c
index bbfd2725215b..23fef3009561 100644
--- a/drivers/net/wireless/ti/wlcore/debugfs.c
+++ b/drivers/net/wireless/ti/wlcore/debugfs.c
@@ -47,6 +47,9 @@ void wl1271_debugfs_update_stats(struct wl1271 *wl)
 {
 	int ret;
 
+	if (!wl->stats.fw_stats)
+		return;
+
 	mutex_lock(&wl->mutex);
 
 	if (unlikely(wl->state != WLCORE_STATE_ON))
@@ -1274,7 +1277,8 @@ static void wl1271_debugfs_add_files(struct wl1271 *wl,
 	DEBUGFS_ADD(irq_pkt_threshold, rootdir);
 	DEBUGFS_ADD(irq_blk_threshold, rootdir);
 	DEBUGFS_ADD(irq_timeout, rootdir);
-	DEBUGFS_ADD(fw_stats_raw, rootdir);
+	if (wl->stats.fw_stats)
+		DEBUGFS_ADD(fw_stats_raw, rootdir);
 	DEBUGFS_ADD(sleep_auth, rootdir);
 	DEBUGFS_ADD(fw_logger, rootdir);
 
@@ -1304,10 +1308,14 @@ int wl1271_debugfs_init(struct wl1271 *wl)
 	rootdir = debugfs_create_dir(KBUILD_MODNAME,
 				     wl->hw->wiphy->debugfsdir);
 
-	wl->stats.fw_stats = kzalloc(wl->stats.fw_stats_len, GFP_KERNEL);
-	if (!wl->stats.fw_stats) {
-		ret = -ENOMEM;
-		goto out_remove;
+	/* A lower driver without firmware statistics leaves fw_stats_len 0 */
+	if (wl->stats.fw_stats_len) {
+		wl->stats.fw_stats = kzalloc(wl->stats.fw_stats_len,
+					     GFP_KERNEL);
+		if (!wl->stats.fw_stats) {
+			ret = -ENOMEM;
+			goto out_remove;
+		}
 	}
 
 	wl->stats.fw_stats_update = jiffies;

-- 
2.56.0

