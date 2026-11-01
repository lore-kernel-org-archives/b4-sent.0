From: Yuvan Shen <yuvanshen09@gmail.com>
Date: Sun, 01 Nov 2026 11:51:58 -0600
Subject: [PATCH] mfd: macsmc: Hold the lock while reading key info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-upstream-macsmc-key-info-v1-1-fa9ff863d199@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD1852oC/yWMQQ6CQAxFr0K6tpEZBROvYliUsUjVGUg7GA3h7
 oIu389/bwZjFTY4FzMov8RkSCu4XQGhp3RjlOvK4EtfO1c6nEbLyhQxUrAY8MEflNQNeHLH4Cr
 qDnXlYdVH5U7ev/Sl+bNN7Z1D3nrboyVjbJVS6LcpkqSnJN5HsswKy/IF2U9hJp4AAAA=
X-Change-ID: 20261101-upstream-macsmc-key-info-714c15af3652
To: Lee Jones <lee@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>
Cc: Neal Gompa <neal@gompa.dev>, Hector Martin <marcan@marcan.st>, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Yuvan Shen <yuvanshen09@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793555518; l=1529;
 i=yuvanshen09@gmail.com; s=20261101; h=from:subject:message-id;
 bh=z1N8QvE7NPiEd4ppeCID6vYGqTPd3Hl1S5pezXvfG2o=;
 b=BQVABoR5+DuuysFyDMIucZZjqkKYPOqazylEB0iamxcetVukCPamNuwomHGvn6It7Fr/X+0ig
 lQwLiEsF6vTB5VoiKka3aujTpTF6rN+mtKM0BJDJACUgCOFDMqRiqzt
X-Developer-Key: i=yuvanshen09@gmail.com; a=ed25519;
 pk=jK3+w+YlV0oJPk7h5w6yT7jKMg0+4IkP9H/eGB+ImJA=
X-Endpoint-Received: by B4 Relay for yuvanshen09@gmail.com/20261101 with auth_id=1380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

apple_smc_get_key_info() releases the SMC mutex when apple_smc_cmd()
returns, and only then copies the reply out of the shared memory buffer.
A command issued by another thread in between can overwrite the buffer,
so the key's size, type and flags can come from a different reply. The
hwmon and power sub-devices call it from their probe functions, while
the other sub-devices may already be issuing commands.

Hold the mutex until the reply has been copied, as apple_smc_read() and
apple_smc_write() do.

Fixes: e038d985c982 ("mfd: Add Apple Silicon System Management Controller")
Cc: stable@vger.kernel.org
Signed-off-by: Yuvan Shen <yuvanshen09@gmail.com>
---
 drivers/mfd/macsmc.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/mfd/macsmc.c b/drivers/mfd/macsmc.c
index 514cba7dc897..4dbaacc7eb3d 100644
--- a/drivers/mfd/macsmc.c
+++ b/drivers/mfd/macsmc.c
@@ -210,7 +210,9 @@ int apple_smc_get_key_info(struct apple_smc *smc, smc_key key, struct apple_smc_
 	u8 key_info[6];
 	int ret;
 
-	ret = apple_smc_cmd(smc, SMC_MSG_GET_KEY_INFO, key, 0, 0, NULL);
+	guard(mutex)(&smc->mutex);
+
+	ret = apple_smc_cmd_locked(smc, SMC_MSG_GET_KEY_INFO, key, 0, 0, NULL);
 	if (ret >= 0 && info) {
 		memcpy_fromio(key_info, smc->shmem.iomem, sizeof(key_info));
 		info->size = key_info[0];

---
base-commit: d89e1d186ec9271bf78e62771779e9fc03bf0fc3
change-id: 20261101-upstream-macsmc-key-info-714c15af3652

Best regards,
--  
Yuvan Shen <yuvanshen09@gmail.com>

