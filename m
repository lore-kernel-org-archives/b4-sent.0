From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 19:22:27 +0000
Subject: [PATCH] ASoC: soc-pcm: Track BE pause per FE-BE link
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-asoc-dpcm-pause-link-v1-1-5b97347b5771@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHJM/2oC/yXMQQ6CMBBA0auQWTtJy6JYr2JclGHQUShNBwgJ4
 e5UXb7F/zsoZ2GFW7VD5lVUplhgLxXQK8Qno3TFUJvaWWs9Bp0Iu0QjprAo4yDxgz0Z471rGr4
 6KGnK3Mv2294ff+vSvpnm7wuO4wQ3U+OfeAAAAA==
X-Change-ID: 20261119-asoc-dpcm-pause-link-fc0099677e86
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: yung-chuan.liao@linux.intel.com, peter.ujfalusi@linux.intel.com, 
 pierre-louis.bossart@linux.dev, linux-sound@vger.kernel.org, 
 ranjani.sridharan@linux.intel.com, tiwai@suse.com, perex@perex.cz, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795116146; l=8746;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=4C650DEg2dJcUQXRO0XqGJGwNuJChmHAgof5km+wyL4=;
 b=yZaAU6IjISW/kzA1PSfK1RYPX/RodjpeACTUg/mMBrEeJVjBpz9MOM2EUu3l7V9B41HG3XCqL
 cys3fHgoH5hCG5kuzJLq9sVTKks4ukbfV/HJ6GnXZ0YajwPh1WVrFGu
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

Commit 9995c1d096c8 ("ASoC: soc-pcm: improve BE transition for
PAUSE_RELEASE") counts paused FEs in be_pause and remembers in
fe->dpcm[stream].fe_pause that a FE is paused. But fe_pause is one
flag for the FE, while the pause it records is counted in each of its
BEs separately, and nothing tells which BEs hold this FE's pause. The
counts go wrong when a BE trigger fails or a FE has several BEs:

 - When the BE PAUSE_RELEASE fails, fe_pause and be_pause are left
   updated. The BE is still PAUSED, so the PAUSE_PUSH the PCM core
   sends to undo the release skips it. After a retried release
   be_pause is -1, and the next STOP sends PAUSE_PUSH to the BE instead
   of STOP.

 - When the BE PAUSE_PUSH fails, the PCM core undoes it with
   PAUSE_RELEASE, which increments be_start although this FE never
   left it. be_start ends up at 2 and STOP never stops the BE.

 - When the release of one BE fails, the PAUSE_PUSH undo is also
   applied to BEs that the release had not reached yet. For a BE shared
   with a running FE that pauses it under the other FE.

 - Compress offload can stop a paused stream directly. When two FEs
   share a BE and the paused one is stopped while the other is
   running, STOP takes the paused FE out of be_start a second time and
   stops the BE under the running FE.

Keep the pause in struct snd_soc_dpcm, which links one FE to one BE,
instead:

 - PAUSE_PUSH marks the link and skips a link that is already marked;
 - PAUSE_RELEASE only releases a marked link;
 - STOP drops the pause of a marked link instead of touching be_start;
 - a failed BE trigger rolls back just that link.

When a suspended stream that was previously paused is prepared or
closed without first being resumed, no PAUSE_RELEASE or STOP trigger
is sent for that stream. START therefore consumes any pause left on
its link, and closing the link drops any remaining pause under the
BE stream lock.

Found with a static analysis tool and checked by hand.

Fixes: 9995c1d096c8 ("ASoC: soc-pcm: improve BE transition for PAUSE_RELEASE")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm with clang (sound/soc builds, W=1 clean for
soc-pcm.c); not run on hardware.

I checked the bookkeeping with a model of the START, PAUSE_PUSH,
PAUSE_RELEASE and STOP branches, BE prepare/startup/close, and the
callers (single-substream undo, retries of the failed linked-group
member, and compressed streams without automatic undo, including
compress STOP from PAUSED). The model runs 14
sequences; with this patch every one ends with the BEs stopped and
be_start/be_pause back at 0. These sequences send the same BE commands
as before: start/pause/release/stop, pause then stop, the shared-BE
sequence from 9995c1d096c8, pause + system suspend + prepare + start +
stop, and pause + system suspend + close + reopen + start + stop. It is
a model of the counters, not a test on a device.
---
 include/sound/soc-dpcm.h |  4 ++-
 sound/soc/soc-pcm.c      | 69 +++++++++++++++++++++++++++++++++++++-----------
 2 files changed, 57 insertions(+), 16 deletions(-)

diff --git a/include/sound/soc-dpcm.h b/include/sound/soc-dpcm.h
index af24665e37e8..801ad83abfe8 100644
--- a/include/sound/soc-dpcm.h
+++ b/include/sound/soc-dpcm.h
@@ -73,6 +73,9 @@ struct snd_soc_dpcm {
 	/* link state */
 	enum snd_soc_dpcm_link_state state;
 
+	/* FE paused this BE: counted in be_pause, not in be_start */
+	bool paused;
+
 	/* list of BE and FE for this DPCM link */
 	struct list_head list_be;
 	struct list_head list_fe;
@@ -100,7 +103,6 @@ struct snd_soc_dpcm_runtime {
 
 	int be_start; /* refcount protected by BE stream pcm lock */
 	int be_pause; /* refcount protected by BE stream pcm lock */
-	bool fe_pause; /* used to track STOP after PAUSE */
 };
 
 #define for_each_dpcm_fe(be, stream, _dpcm)				\
diff --git a/sound/soc/soc-pcm.c b/sound/soc/soc-pcm.c
index ef8ccf52798e..cb8d23756b1e 100644
--- a/sound/soc/soc-pcm.c
+++ b/sound/soc/soc-pcm.c
@@ -1685,6 +1685,17 @@ void dpcm_be_dai_stop(struct snd_soc_pcm_runtime *fe, int stream,
 		if (!snd_soc_dpcm_can_be_update(fe, be, stream))
 			continue;
 
+		/*
+		 * A pause may survive until close, e.g. after system suspend.
+		 * Drop the pause this link still holds.
+		 */
+		if (dpcm->paused) {
+			snd_pcm_stream_lock_irq(be_substream);
+			dpcm->paused = false;
+			be->dpcm[stream].be_pause--;
+			snd_pcm_stream_unlock_irq(be_substream);
+		}
+
 		if (be->dpcm[stream].users == 0) {
 			dev_err(be->dev, "ASoC: no users %s at close - state %s\n",
 				snd_pcm_direction_name(stream),
@@ -2220,7 +2231,7 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			       int cmd)
 {
 	struct snd_soc_pcm_runtime *be;
-	bool pause_stop_transition;
+	bool was_paused;
 	struct snd_soc_dpcm *dpcm;
 	unsigned long flags;
 	int ret = 0;
@@ -2248,6 +2259,16 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			    (be->dpcm[stream].state != SND_SOC_DPCM_STATE_PAUSED))
 				goto next;
 
+			/*
+			 * A stream suspended while paused and prepared again
+			 * starts without a PAUSE_RELEASE: drop its pause here.
+			 */
+			was_paused = dpcm->paused;
+			if (was_paused) {
+				dpcm->paused = false;
+				be->dpcm[stream].be_pause--;
+			}
+
 			be->dpcm[stream].be_start++;
 			if (be->dpcm[stream].be_start != 1)
 				goto next;
@@ -2260,6 +2281,10 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 						      SNDRV_PCM_TRIGGER_START);
 			if (ret) {
 				be->dpcm[stream].be_start--;
+				if (was_paused) {
+					dpcm->paused = true;
+					be->dpcm[stream].be_pause++;
+				}
 				goto next;
 			}
 
@@ -2287,7 +2312,11 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			    (be->dpcm[stream].state != SND_SOC_DPCM_STATE_PAUSED))
 				goto next;
 
-			fe->dpcm[stream].fe_pause = false;
+			/* nothing to release if this FE didn't pause this BE */
+			if (!dpcm->paused)
+				goto next;
+
+			dpcm->paused = false;
 			be->dpcm[stream].be_pause--;
 
 			be->dpcm[stream].be_start++;
@@ -2297,6 +2326,8 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			ret = soc_pcm_trigger(be_substream, cmd);
 			if (ret) {
 				be->dpcm[stream].be_start--;
+				dpcm->paused = true;
+				be->dpcm[stream].be_pause++;
 				goto next;
 			}
 
@@ -2307,30 +2338,32 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			    (be->dpcm[stream].state != SND_SOC_DPCM_STATE_PAUSED))
 				goto next;
 
-			if (be->dpcm[stream].state == SND_SOC_DPCM_STATE_START)
+			/*
+			 * A paused FE left be_start when it paused and only
+			 * holds a pause on this BE.
+			 */
+			was_paused = dpcm->paused;
+			if (was_paused) {
+				dpcm->paused = false;
+				be->dpcm[stream].be_pause--;
+			} else if (be->dpcm[stream].state == SND_SOC_DPCM_STATE_START) {
 				be->dpcm[stream].be_start--;
+			}
 
 			if (be->dpcm[stream].be_start != 0)
 				goto next;
 
-			pause_stop_transition = false;
-			if (fe->dpcm[stream].fe_pause) {
-				pause_stop_transition = true;
-				fe->dpcm[stream].fe_pause = false;
-				be->dpcm[stream].be_pause--;
-			}
-
 			if (be->dpcm[stream].be_pause != 0)
 				ret = soc_pcm_trigger(be_substream, SNDRV_PCM_TRIGGER_PAUSE_PUSH);
 			else
 				ret = soc_pcm_trigger(be_substream, SNDRV_PCM_TRIGGER_STOP);
 
 			if (ret) {
-				if (be->dpcm[stream].state == SND_SOC_DPCM_STATE_START)
-					be->dpcm[stream].be_start++;
-				if (pause_stop_transition) {
-					fe->dpcm[stream].fe_pause = true;
+				if (was_paused) {
+					dpcm->paused = true;
 					be->dpcm[stream].be_pause++;
+				} else if (be->dpcm[stream].state == SND_SOC_DPCM_STATE_START) {
+					be->dpcm[stream].be_start++;
 				}
 				goto next;
 			}
@@ -2361,7 +2394,11 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			if (be->dpcm[stream].state != SND_SOC_DPCM_STATE_START)
 				goto next;
 
-			fe->dpcm[stream].fe_pause = true;
+			/* this FE's pause is already counted on this BE */
+			if (dpcm->paused)
+				goto next;
+
+			dpcm->paused = true;
 			be->dpcm[stream].be_pause++;
 
 			be->dpcm[stream].be_start--;
@@ -2371,6 +2408,8 @@ int dpcm_be_dai_trigger(struct snd_soc_pcm_runtime *fe, int stream,
 			ret = soc_pcm_trigger(be_substream, cmd);
 			if (ret) {
 				be->dpcm[stream].be_start++;
+				dpcm->paused = false;
+				be->dpcm[stream].be_pause--;
 				goto next;
 			}
 



