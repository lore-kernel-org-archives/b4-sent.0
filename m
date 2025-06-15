From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 16 Jun 2025 00:01:10 +0800
Subject: [PATCH] i2c: qup: jump out of the loop in case of timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250616-qca-i2c-v1-1-2a8d37ee0a30@outlook.com>
X-B4-Tracking: v=1; b=H4sIAEbuTmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDM0NT3cLkRN1Mo2TdFBPDpCQzw8REU8tUJaDqgqLUtMwKsEnRsbW1ACh
 PBhNZAAAA
To: Andi Shyti <andi.shyti@kernel.org>, 
 Stephan Gerhold <stephan.gerhold@kernkonzept.com>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750003271; l=1276;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=7A4MyX2wBo/3swedAnLq8MA5y/hamSq89OQJdzuf1oA=;
 b=TYce6RfqS10iEeMra5WRsEso/JZvK/1nNmpkB8vrnFU1IEaN1FN/sM8Acao00LTn63aEfJj7x
 M/7eiwbqmFDAE+0bJ6f3myfi92GEKMeyGL+3pN2T7gKsicrMi3I+wvc
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Original logic only sets the return value but doesn't jump out of the
loop if the bus is kept active by a client. This is not expected. A
malicious or buggy i2c client can hang the kernel in this case and
should be avoided. This is observed during a long time test with a
PCA953x GPIO extender.

Fix it by changing the logic to not only sets the return value, but also
jumps out of the loop and return to the caller with -ETIMEDOUT.

Cc: stable@vger.kernel.org
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/i2c/busses/i2c-qup.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/i2c/busses/i2c-qup.c b/drivers/i2c/busses/i2c-qup.c
index 3a36d682ed57..5b053e51f4c9 100644
--- a/drivers/i2c/busses/i2c-qup.c
+++ b/drivers/i2c/busses/i2c-qup.c
@@ -452,8 +452,10 @@ static int qup_i2c_bus_active(struct qup_i2c_dev *qup, int len)
 		if (!(status & I2C_STATUS_BUS_ACTIVE))
 			break;
 
-		if (time_after(jiffies, timeout))
+		if (time_after(jiffies, timeout)) {
 			ret = -ETIMEDOUT;
+			break;
+		}
 
 		usleep_range(len, len * 2);
 	}

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250615-qca-i2c-d41bb61aa59e

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

