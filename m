From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 05:57:45 +0000
Subject: [PATCH] PM / devfreq: Resume at the frequency from before suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-devfreq-resume-freq-v1-1-90de450ccbd0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5EQBCE4VeRPpvETETEq2wcGDW0hLXdSyTi3
 Q1u9R3qP0ghDKUqOUiwsfJ3jrBpQn5o5h6Gu2hymSustZnpsAXBzwh0nWCejdyhQVuEMpQUn4s
 g8P5UP/VrXdsR/n+n6DwvjWdj2ncAAAA=
X-Change-ID: 20261110-devfreq-resume-freq-e42eaeb6f8f8
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Dong Aisheng <aisheng.dong@nxp.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794290264; l=2896;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=tdlutxMME+GnXd+M6y/2TwHqtzvKQ3bamAdqTwwxsDk=;
 b=/P0AlERKNeMv1oK1rQ9ScANECsCNBtd20fQ+QTuJVNIhjjR+2oRX3S8mzeF6DN85r7uIEXRt6
 D+sclVwSoGcA/oxPBAyDjs1RGYKWO/3ti1RlG4PrSyDGbGCzBc0tWZG
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

devfreq_suspend_device() moves a device that has a suspend OPP to that
frequency with devfreq_set_target(). Since commit 62453f1ba5d5 ("PM /
devfreq: Use more accurate returned new_freq as resume_freq"),
devfreq_set_target() records the frequency it has just set as
resume_freq, so the suspend transition itself overwrites the frequency
to resume at with the suspend frequency. devfreq_resume_device() then
"restores" the suspend frequency and the device stays there until the
governor next re-evaluates it.

For system suspend that only costs one polling interval. For a driver
that calls devfreq_suspend_device() from runtime PM, such as panthor,
every runtime resume starts at the lowest OPP: with a 50 ms autosuspend
delay and a 50 ms polling interval, short bursts of GPU work after an
idle period run at the suspend frequency.

Save the frequency the device ran at before the suspend transition and
use that as resume_freq, as the code did before that commit. Requests
made while the device is suspended still update resume_freq through
devfreq_set_target(), as before.

Fixes: 62453f1ba5d5 ("PM / devfreq: Use more accurate returned new_freq as resume_freq")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
The bug was found on an RK3588 board (panthor, runtime PM through
devfreq_suspend_device()). The patch runs in that board's v7.3-based
kernel. I could not test it on a second platform: my Allwinner H616
board has no suspend OPP, so the changed path is not taken there.

This patch was developed with Claude (Anthropic) as a coding
assistant: it wrote the code and the commit message.
I reviewed it and tested it as described above.
---
 drivers/devfreq/devfreq.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/devfreq/devfreq.c b/drivers/devfreq/devfreq.c
index f08fc6966eae..043cdc37bd0b 100644
--- a/drivers/devfreq/devfreq.c
+++ b/drivers/devfreq/devfreq.c
@@ -1146,6 +1146,7 @@ EXPORT_SYMBOL(devm_devfreq_remove_device);
  */
 int devfreq_suspend_device(struct devfreq *devfreq)
 {
+	unsigned long resume_freq;
 	int ret;
 
 	if (!devfreq)
@@ -1163,7 +1164,15 @@ int devfreq_suspend_device(struct devfreq *devfreq)
 
 	if (devfreq->suspend_freq) {
 		mutex_lock(&devfreq->lock);
+		/*
+		 * devfreq_set_target() records the frequency it sets as the
+		 * one to resume at. Keep the frequency from before suspend
+		 * instead, so that the device does not resume at its suspend
+		 * frequency.
+		 */
+		resume_freq = devfreq->previous_freq;
 		ret = devfreq_set_target(devfreq, devfreq->suspend_freq, 0);
+		devfreq->resume_freq = resume_freq;
 		mutex_unlock(&devfreq->lock);
 		if (ret)
 			return ret;

---
base-commit: 9a222650d9e70d0027126e4df5b00b1b5b678a97
change-id: 20261110-devfreq-resume-freq-e42eaeb6f8f8

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

