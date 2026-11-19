From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Thu, 19 Nov 2026 20:22:07 +0200
Subject: [PATCH] EDAC/mc: Convert the poll period to jiffies when it is
 changed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-edac-mc-poll-msec-jiffies-v1-1-fe329938fa09@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDQAxA4atI1g00s1DsVUoXGhON+MdEpSDev
 aNdfov3DnCJJg6v7IAou7nNUwI9MuCumlpBa5IhPENORCVKUzGOjMs8DDi6MPammhaodaFlyJU
 oMKR+iaL2vd/vz9++1b3weg3hPH9wNnipfQAAAA==
X-Change-ID: 20261119-edac-mc-poll-msec-jiffies-fb7f926f112c
To: Borislav Petkov <bp@alien8.de>, Tony Luck <tony.luck@intel.com>
Cc: linux-edac@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795112528; l=2158;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=aXLz/0TM/M/jsqG2Y3hoOozntxY6jGOuwYADUxDIanU=;
 b=JibszSrF34HNAx3ksLTf9r3T3IHPqQO7pvSdwgNI9iqEH1zGTiN8cA4M+F1rj7FnIKBbPO9zt
 gQE25XHAnmbDToEi5vA9fbJjx+dhONnlkELxKhhDOaD55hEnmhvx+RZ
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing edac_mc_poll_msec at run time re-arms every polled memory
controller through edac_mc_reset_delay_period(), which passes the new
value to edac_mod_work() as it is. mod_delayed_work() takes jiffies, so
the first poll after the write comes "value" jiffies later rather than
"value" milliseconds: at HZ=300, writing 2000 puts the next poll 6.7 s
out. edac_mc_workq_function() re-arms with msecs_to_jiffies(), so only
that first poll is off.

Before commit c4cf3b454eca ("EDAC: Rework workqueue handling") this
path converted the value through edac_mc_workq_setup(), and
edac_device_reset_delay_period() still does. Convert it here as well.

Fixes: c4cf3b454eca ("EDAC: Rework workqueue handling")
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
I noticed this while timing ie31200_edac's polls in a KVM guest: the
first poll after a write to edac_mc_poll_msec came late.

Tested on v7.4-rc3+ (4405c18c95d2) at HZ=300, with ie31200_edac bound
to a QEMU model of the Kaby Lake host bridge (a local device model, not
upstream QEMU), timing edac_mc_workq_function() with a kprobe. Without
the patch the first poll came 6.76 s after writing 2000 and 3.51 s after
writing 1000, with the polls after it every 2.13 s and 1.01 s. With the
patch the first poll comes 2.14 s and 1.02 s after the write, the same
as the ones after it. Writes below 1000 are still rejected.
---
 drivers/edac/edac_mc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/edac/edac_mc.c b/drivers/edac/edac_mc.c
index fd70caa85574..787bef803ef0 100644
--- a/drivers/edac/edac_mc.c
+++ b/drivers/edac/edac_mc.c
@@ -499,7 +499,7 @@ void edac_mc_reset_delay_period(unsigned long value)
 		mci = list_entry(item, struct mem_ctl_info, link);
 
 		if (mci->op_state == OP_RUNNING_POLL)
-			edac_mod_work(&mci->work, value);
+			edac_mod_work(&mci->work, msecs_to_jiffies(value));
 	}
 	mutex_unlock(&mem_ctls_mutex);
 }

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-edac-mc-poll-msec-jiffies-fb7f926f112c

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

