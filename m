From: Jake Hillion <jake@hillion.co.uk>
Date: Fri, 30 May 2025 17:15:21 +0100
Subject: [PATCH 1/2] x86/platform/amd: move final timeout check to after
 final sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250530-amd-hsmp-v1-1-3222bffa4008@hillion.co.uk>
References: <20250530-amd-hsmp-v1-0-3222bffa4008@hillion.co.uk>
In-Reply-To: <20250530-amd-hsmp-v1-0-3222bffa4008@hillion.co.uk>
To: Naveen Krishna Chatradhi <naveenkrishna.chatradhi@amd.com>, 
 Carlos Bilbao <carlos.bilbao@kernel.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 sched-ext@meta.com, Jake Hillion <jake@hillion.co.uk>, 
 Blaise Sanouillet <linux@blaise.sanouillet.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748621741; l=1760;
 i=jake@hillion.co.uk; s=20250530; h=from:subject:message-id;
 bh=4EV5qkO85AXhQhZuF40dcwxkZ1W5E4mea6iYRbqFyME=;
 b=xjApLCcXbb/4z3p6GORkeT1jDsc2Rt6qJRaECX1Dq6LZy1MStYB8zbFBtnV17nUNRboTmtBI9
 yTFLmXUaVYsBoJ3UfAwjyHXOISz0UR3AuuPcqMFITVl9jHJbppFd7r6
X-Developer-Key: i=jake@hillion.co.uk; a=ed25519;
 pk=8cznmqtMcMEcU8QH55k8DrySboD889OBB/BEUMJh3dw=
X-Endpoint-Received: by B4 Relay for jake@hillion.co.uk/20250530 with auth_id=419
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__hsmp_send_message sleeps between result read attempts and has a
timeout of 100ms. Under extreme load it's possible for these sleeps to
take a long time, exceeding the 100ms. In this case the current code
does not check the register and fails with ETIMEDOUT.

Refactor the loop to ensure there is at least one read of the register
after a sleep of any duration. This removes instances of ETIMEDOUT with
a single caller, even with a misbehaving scheduler. Tested on AMD
Bergamo machines.

Suggested-by: Blaise Sanouillet <linux@blaise.sanouillet.com>
Signed-off-by: Jake Hillion <jake@hillion.co.uk>
---
 drivers/platform/x86/amd/hsmp/hsmp.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/platform/x86/amd/hsmp/hsmp.c b/drivers/platform/x86/amd/hsmp/hsmp.c
index e262e8a97b4542a389e09a82dad71f7d2e8b2449..f35c639457ac425e79dead2515c0eddea0759323 100644
--- a/drivers/platform/x86/amd/hsmp/hsmp.c
+++ b/drivers/platform/x86/amd/hsmp/hsmp.c
@@ -99,7 +99,7 @@ static int __hsmp_send_message(struct hsmp_socket *sock, struct hsmp_message *ms
 	short_sleep = jiffies + msecs_to_jiffies(HSMP_SHORT_SLEEP);
 	timeout	= jiffies + msecs_to_jiffies(HSMP_MSG_TIMEOUT);
 
-	while (time_before(jiffies, timeout)) {
+	while (true) {
 		ret = sock->amd_hsmp_rdwr(sock, mbinfo->msg_resp_off, &mbox_status, HSMP_RD);
 		if (ret) {
 			dev_err(sock->dev, "Error %d reading mailbox status\n", ret);
@@ -108,6 +108,10 @@ static int __hsmp_send_message(struct hsmp_socket *sock, struct hsmp_message *ms
 
 		if (mbox_status != HSMP_STATUS_NOT_READY)
 			break;
+
+		if (!time_before(jiffies, timeout))
+			break;
+
 		if (time_before(jiffies, short_sleep))
 			usleep_range(50, 100);
 		else

-- 
2.47.2

