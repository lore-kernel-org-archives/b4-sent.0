From: Jake Hillion <jake@hillion.co.uk>
Date: Fri, 30 May 2025 17:15:22 +0100
Subject: [PATCH 2/2] x86/platform/amd: replace down_timeout with
 down_interruptible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250530-amd-hsmp-v1-2-3222bffa4008@hillion.co.uk>
References: <20250530-amd-hsmp-v1-0-3222bffa4008@hillion.co.uk>
In-Reply-To: <20250530-amd-hsmp-v1-0-3222bffa4008@hillion.co.uk>
To: Naveen Krishna Chatradhi <naveenkrishna.chatradhi@amd.com>, 
 Carlos Bilbao <carlos.bilbao@kernel.org>, 
 Hans de Goede <hdegoede@redhat.com>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 sched-ext@meta.com, Jake Hillion <jake@hillion.co.uk>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748621741; l=1695;
 i=jake@hillion.co.uk; s=20250530; h=from:subject:message-id;
 bh=QAHzX1+6Dbbm88Tx2DVSQQq09t9e4710Uyoh5Lrpb0o=;
 b=bPFG2Kfuu/Iy7NIuGI3wee7kIwEkO5Wlnw8PECvDRTAOUIcRsmmm1HaMc7adFbQo7H4Z1Adql
 n5WBJDcjxCsB7rQbrRLj61XBiU97Vst4pXEQuRSZr/2Je0kLM4vdTmE
X-Developer-Key: i=jake@hillion.co.uk; a=ed25519;
 pk=8cznmqtMcMEcU8QH55k8DrySboD889OBB/BEUMJh3dw=
X-Endpoint-Received: by B4 Relay for jake@hillion.co.uk/20250530 with auth_id=419
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently hsmp_send_message uses down_timeout with a 100ms timeout to
take the semaphore. However __hsmp_send_message, the content of the
critical section, has a sleep in it. On systems with significantly
delayed scheduling behaviour this may take over 100ms.

Convert this method to down_interruptible. Leave the error handling the
same as the documentation currently is not specific about what error is
returned.

Previous behaviour: a caller who competes with another caller stuck in
the critical section due to scheduler delays would receive -ETIMEDOUT.

New behaviour: a caller who competes with another caller stuck in the
critical section due to scheduler delays will complete successfully.

Signed-off-by: Jake Hillion <jake@hillion.co.uk>
---
 drivers/platform/x86/amd/hsmp/hsmp.c | 8 +-------
 1 file changed, 1 insertion(+), 7 deletions(-)

diff --git a/drivers/platform/x86/amd/hsmp/hsmp.c b/drivers/platform/x86/amd/hsmp/hsmp.c
index f35c639457ac425e79dead2515c0eddea0759323..6c30bb3edc1d77939b10047b771a5c574e5f2a1e 100644
--- a/drivers/platform/x86/amd/hsmp/hsmp.c
+++ b/drivers/platform/x86/amd/hsmp/hsmp.c
@@ -216,13 +216,7 @@ int hsmp_send_message(struct hsmp_message *msg)
 		return -ENODEV;
 	sock = &hsmp_pdev.sock[msg->sock_ind];
 
-	/*
-	 * The time taken by smu operation to complete is between
-	 * 10us to 1ms. Sometime it may take more time.
-	 * In SMP system timeout of 100 millisecs should
-	 * be enough for the previous thread to finish the operation
-	 */
-	ret = down_timeout(&sock->hsmp_sem, msecs_to_jiffies(HSMP_MSG_TIMEOUT));
+	ret = down_interruptible(&sock->hsmp_sem);
 	if (ret < 0)
 		return ret;
 

-- 
2.47.2

