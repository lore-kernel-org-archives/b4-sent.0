From: Zeliang Li <lizeliang.linux@gmail.com>
Date: Sat, 15 Aug 2026 03:45:55 +0800
Subject: [PATCH v2] ALSA: hda/tas2781: Add hardware stabilization delay
 during firmware load retries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260815-master-v2-1-b4ea03c8b59e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDC0NT3dzE4pLUIt1Ei8TUJAszU2NzY2MloOKCotS0zAqwQdGxtbUAi4q
 UmlgAAAA=
X-Change-ID: 20260815-master-a8aeb8653733
To: Shenghao Ding <shenghao-ding@ti.com>, Kevin Lu <kevin-lu@ti.com>, 
 Baojun Xu <baojun.xu@ti.com>, Sen Wang <sen@ti.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Zeliang Li <lizeliang.linux@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786736756; l=2319;
 i=lizeliang.linux@gmail.com; s=20260815; h=from:subject:message-id;
 bh=iF4laLe0Y1wmQtGMkQjEFcYrO7/o6+MwaO3jA4IuTaU=;
 b=6ukA7NivbzFoWP8lKHr3dZU+bm/LEQwRMq+PwWK3YwowiRcFQJDhnf3izmfaJD4A/m6yG1Hsu
 hSsUsNDolH9B2AlosnE1olimvAcqdUw3mugJz6iKDYrzoyys0W0BYmW
X-Developer-Key: i=lizeliang.linux@gmail.com; a=ed25519;
 pk=bDbGmUHqOf5ihCzM1cEQenmfHBqy7pSFeJvBEpeJsyM=
X-Endpoint-Received: by B4 Relay for lizeliang.linux@gmail.com/20260815 with auth_id=951
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During runtime resume transitions, loading calibration data blocks
to the tas2781 amplifier may intermittently trigger transmission
failures or block checksum mismatches (-EAGAIN) due to un-stabilized
power rails or I2C bus glitches.

The loop in tasdev_load_blk() decrements block->nr_retry and attempts
an immediate re-transmission upon receiving -EAGAIN. However, without
any inter-retry delay, all available retry slots are exhausted within
less than a microsecond—long before the hardware can physically
settle. This leads to permanent "ERROR_PRAM_CRCCHK" deadlocks and
silent speakers on modern laptops after resuming media.

Fix this cleanly by introducing a 2ms usleep_range() delay directly
inside the tasdev_load_blk() retry paths prior to each 'continue'
statement. This grants the chip sufficient time to stabilize before
the next transmission attempt without introducing unnecessary latency
on final failures.

Signed-off-by: Zeliang Li <lizeliang.linux@gmail.com>
---
 sound/soc/codecs/tas2781-fmwlib.c | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/sound/soc/codecs/tas2781-fmwlib.c b/sound/soc/codecs/tas2781-fmwlib.c
index dcbeb9618195..bfabff583d57 100644
--- a/sound/soc/codecs/tas2781-fmwlib.c
+++ b/sound/soc/codecs/tas2781-fmwlib.c
@@ -1849,16 +1849,26 @@ static int tasdev_load_blk(struct tasdevice_priv *tas_priv,
 			}
 		}
 		if (ret == -EAGAIN) {
-			if (block->nr_retry > 0)
+			if (block->nr_retry > 0) {
+				/* Give the hardware time to stabilize before
+				 * next block re-transmission attempt.
+				 */
+				usleep_range(2000, 2500);
 				continue;
+			}
 		} else if (ret < 0) /*err in current device, skip it*/
 			break;
 
 		if (block->is_pchksum_present) {
 			ret = tasdev_block_chksum(tas_priv, block, chn);
 			if (ret == -EAGAIN) {
-				if (block->nr_retry > 0)
+				if (block->nr_retry > 0) {
+					/* Give the bus time to recover after
+					 * a checksum mismatch error.
+					 */
+					usleep_range(2000, 2500);
 					continue;
+				}
 			} else if (ret < 0) /*err in current device, skip it*/
 				break;
 		}

---
base-commit: a5161661ae99f497affa83a5b8654e457cda6267
change-id: 20260815-master-a8aeb8653733

Best regards,
-- 
Zeliang Li <lizeliang.linux@gmail.com>

