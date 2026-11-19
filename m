From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 21:16:22 +0000
Subject: [PATCH v3 1/2] PM / devfreq: Resume at the frequency from before
 suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-devfreq-suspend-sync-v3-1-ef19fbf94d83@gmail.com>
References: <20261119-devfreq-suspend-sync-v3-0-ef19fbf94d83@gmail.com>
In-Reply-To: <20261119-devfreq-suspend-sync-v3-0-ef19fbf94d83@gmail.com>
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Steven Price <steven.price@arm.com>, Liviu Dudau <liviu.dudau@arm.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Dong Aisheng <aisheng.dong@nxp.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795122981; l=1549;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=oC9Ygc0eVTfT2xaSEZ90RmzA2OhUbylQMx8o+6M4NjQ=;
 b=a+90IYhYKf1h6Ux+adzDZV+Qjhih4NuCO71zC0xrnOw4fpcJqRNftizSH87J0a4n+enuZBakz
 v0mlh7bMa9CCoNK1l5KuzDvAbuk1TKWCPcL4SD3lNRgupiYCXb2xnfI
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 62453f1ba5d5 ("PM / devfreq: Use more accurate returned
new_freq as resume_freq"), devfreq_set_target() records the frequency it
sets as resume_freq, so the suspend transition in
devfreq_suspend_device() overwrites it with the suspend frequency. The
device then resumes at its suspend frequency and stays there until the
governor's next update; with runtime PM (e.g. lima on RK3528) that is
after every idle period.

Keep the frequency from before the suspend transition as resume_freq.

Fixes: 62453f1ba5d5 ("PM / devfreq: Use more accurate returned new_freq as resume_freq")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/devfreq/devfreq.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/devfreq/devfreq.c b/drivers/devfreq/devfreq.c
index f25304bca37f..795a01d012ec 100644
--- a/drivers/devfreq/devfreq.c
+++ b/drivers/devfreq/devfreq.c
@@ -1144,6 +1144,7 @@ EXPORT_SYMBOL(devm_devfreq_remove_device);
  */
 int devfreq_suspend_device(struct devfreq *devfreq)
 {
+	unsigned long resume_freq;
 	int ret;
 
 	if (!devfreq)
@@ -1161,7 +1162,10 @@ int devfreq_suspend_device(struct devfreq *devfreq)
 
 	if (devfreq->suspend_freq) {
 		mutex_lock(&devfreq->lock);
+		/* devfreq_set_target() overwrites resume_freq; keep the pre-suspend one */
+		resume_freq = devfreq->previous_freq;
 		ret = devfreq_set_target(devfreq, devfreq->suspend_freq, 0);
+		devfreq->resume_freq = resume_freq;
 		mutex_unlock(&devfreq->lock);
 		if (ret)
 			return ret;

-- 
2.55.0

