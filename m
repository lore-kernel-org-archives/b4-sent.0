From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 05:35:37 +0000
Subject: [PATCH 6.6.y] ALSA: seq: Don't leak the extension cell pointer in
 the bounce payload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-alsa-66-v1-1-e6baeea4106a@certik.com>
X-B4-Tracking: v=1; b=H4sIAKgWCWsC/02NSw7CMAxEr1J5jQsJJQiugljk41KjKqnigkBV7
 04CG5bzNPNmAaHMJHBuFsj0ZOEUS1CbBvxg442QQ8mgd9oopY8o6YB2FIvGIPWOgjrtfUcdlMW
 UqefX13YB05r2Ddcfloe7k5+rqRadFUKXbfRDRUIxzCmNWPn27wHW9QPWIRLiogAAAA==
X-Change-ID: 20261127-so5-alsa-66-efbed193c4e4
To: stable@vger.kernel.org
Cc: HyeongJun An <sammiee5311@gmail.com>, Takashi Iwai <tiwai@suse.de>, 
 linux-sound@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795757736; l=4003;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=nGJ91NaFovr+BISLWd06H/MX3/Mv38Fa6V8EKicAbJ4=;
 b=ZlYd1JYkTfkU4c4meREjx9iDEgpue9uA7XF0TuuIpDNQqouvJ9FY8KlhMqzT3mr0baCEvwwUT
 xswXe7PBP8ADbGbuuSQBvqgKWCS3TzxPWNTf6kuDYeuqNpd/l9m3lX+
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: HyeongJun An <sammiee5311@gmail.com>

commit 59e1592d3c270ff4642d5d6dc55c545306eb0693 upstream.

The bounce_error_event() embeds the failed event in the bounce payload
by pointing data.ext.ptr at it.  When that event is a queued
variable-length event, its own data.ext.ptr holds the address of its
first extension cell, put there by snd_seq_event_dup().  The payload
goes out verbatim through snd_seq_expand_var_event(), so the address
reaches userspace.

That is the same address commit 705dd6dcbc0e ("ALSA: seq: Clear
variable event pointer on read") removed from the event header.  The
read path still clears it there, just above the call that expands the
payload.

Embed a sanitised copy instead, treated exactly as snd_seq_read()
treats the header.  A stack copy is enough because delivery is
synchronous and snd_seq_event_dup() copies before returning.

An unprivileged client reaches this by setting SNDRV_SEQ_FILTER_BOUNCE,
queueing a variable-length event to a port that does not exist and
reading the bounce back.  Eight bytes on 64-bit, from its own pool.

Fixes: efc86691e4d8 ("ALSA: seq: Fix kernel heap address leak in bounce_error_event()")
Assisted-by: Claude:claude-opus-5
Signed-off-by: HyeongJun An <sammiee5311@gmail.com>
Link: https://patch.msgid.link/20260811131835.3837024-1-sammiee5311@gmail.com
Signed-off-by: Takashi Iwai <tiwai@suse.de>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y, 6.12.y and newer already have this fix.

Tested on v6.6.163:
- x86_64 allmodconfig W=1 build of sound/core/seq/seq_clientmgr.o,
  base vs patched, no new warnings
- booted the patched kernel under QEMU/KVM with snd-seq-dummy, passed a
  note between two ports and checked the error bounce for a rejected
  fixed-length event. I didn't run a variable-length bounce.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

sound/core/seq/seq_clientmgr.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)
---
 sound/core/seq/seq_clientmgr.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)

diff --git a/sound/core/seq/seq_clientmgr.c b/sound/core/seq/seq_clientmgr.c
index f039fd6ee3a7..de17b66cd16b 100644
--- a/sound/core/seq/seq_clientmgr.c
+++ b/sound/core/seq/seq_clientmgr.c
@@ -578,7 +578,7 @@ static int bounce_error_event(struct snd_seq_client *client,
 			      struct snd_seq_event *event,
 			      int err, int atomic, int hop)
 {
-	struct snd_seq_event bounce_ev;
+	struct snd_seq_event bounce_ev, quoted;
 	int result;
 
 	if (client == NULL ||
@@ -594,15 +594,19 @@ static int bounce_error_event(struct snd_seq_client *client,
 		 * For user clients, send SNDRV_SEQ_EVENT_BOUNCE with the
 		 * original event embedded as variable-length data.  This
 		 * avoids exposing data.quote.event (a kernel pointer) to
-		 * userspace.  The variable-length path in snd_seq_event_dup()
-		 * copies the event data from data.ext.ptr into chained cells,
-		 * and snd_seq_expand_var_event() copies only the data content
-		 * -- never the pointer -- to userspace.
+		 * userspace.  Sanitise the embedded copy too - a queued
+		 * variable-length event carries the address of its own
+		 * extension cell, and the payload goes out verbatim.
 		 */
+		quoted = *event;
+		if (snd_seq_ev_is_variable(&quoted)) {
+			quoted.data.ext.len &= ~SNDRV_SEQ_EXT_MASK;
+			quoted.data.ext.ptr = NULL;
+		}
 		bounce_ev.type = SNDRV_SEQ_EVENT_BOUNCE;
 		bounce_ev.flags = SNDRV_SEQ_EVENT_LENGTH_VARIABLE;
 		bounce_ev.data.ext.len = sizeof(struct snd_seq_event);
-		bounce_ev.data.ext.ptr = (char *)event;
+		bounce_ev.data.ext.ptr = (char *)&quoted;
 	} else {
 		/*
 		 * For kernel clients, quote the event pointer directly.

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261127-so5-alsa-66-efbed193c4e4

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

