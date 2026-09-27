From: Christian Berry <christiankbberry@gmail.com>
Date: Sun, 27 Sep 2026 19:03:49 -0400
Subject: [PATCH] nvme: check for readiness more quickly to speed up boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-nvme-ready-poll-v1-1-6a3f63b0ea3e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBswC6WuEi00pxooCwUpwrsnL
 d/i/xciBaYIQ/VCoMSRT1/Q1BXMm/ErIbtikEIq0UuNPh2EgYx78Dr3HTvrVCdara2xUKor0ML
 3fxynnD+hX8CDYQAAAA==
X-Change-ID: 20260927-nvme-ready-poll-4bd640377bab
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Christian Berry <christiankbberry@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790550238; l=1373;
 i=christiankbberry@gmail.com; s=20260927; h=from:subject:message-id;
 bh=l8Ulibs93iyPd5xJMD4r29EG9Ft858b6i/ATurkctCc=;
 b=qY1NGMDH2pukCyk9JNIs6w8MUSuo7otKu4VfoYh7MPDMpJuNbT2wBOh6JL3liKJilLlZT03pS
 phbajqBqrA6B4jtU3jDlVfYG+tgg+hozpGnUtU0Y60j5RipQzI6F7Is
X-Developer-Key: i=christiankbberry@gmail.com; a=ed25519;
 pk=mIiHYdE/qfTZkSzWp7S7P0suIaXgOgQIn4nfjIhg9+c=
X-Endpoint-Received: by B4 Relay for christiankbberry@gmail.com/20260927 with auth_id=1073
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nvme_wait_ready() polls the controller status every 100ms, although
the controller may become ready much sooner. Every probe then waits
at least 100ms longer than needed, and possibly twice, since both
nvme_disable_ctrl() and nvme_enable_ctrl() wait for readiness.

Poll every millisecond instead, as Linux does since commit
3e98c2443f5c ("nvme: Check for readiness more quickly, to speed up
boot time"). The overall timeout is still based on elapsed time, so
it is unaffected.

Tested on an Arm64 SoC with a Samsung 980 SSD in a Gen3 x4
configuration, where PCIe + NVMe probe time dropped from 165 ms to
65 ms.

Signed-off-by: Christian Berry <christiankbberry@gmail.com>
---
 drivers/nvme/host/core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/nvme/host/core.c b/drivers/nvme/host/core.c
index 345707ecfe..9686268d44 100644
--- a/drivers/nvme/host/core.c
+++ b/drivers/nvme/host/core.c
@@ -173,7 +173,7 @@ static int nvme_wait_ready(struct nvme_ctrl *ctrl, u64 cap, bool enabled)
 		if ((csts & NVME_CSTS_RDY) == bit)
 			break;
 
-		mdelay(100);
+		udelay(1000);
 
 		if (is_timeout(start, timeout)) {
 			dev_err(ctrl->dev,

---
base-commit: 983608b439b803f72f12d56d0ab10bd6ba29e536
change-id: 20260927-nvme-ready-poll-4bd640377bab

Best regards,
-- 
Christian Berry <christiankbberry@gmail.com>

