From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 13 Nov 2024 13:57:15 +0800
Subject: [PATCH] rtc: amlogic-a4: fix compile error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241113-fix_a4_rtc-v1-1-307af26449a8@amlogic.com>
X-B4-Tracking: v=1; b=H4sIALo/NGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQ0Nj3bTMivhEk/iikmTdNCNTgzQzs+SkJENDJaCGgqJUoCzYsOjY2lo
 ApYvmJ1wAAAA=
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: Stephen Rothwell <sfr@canb.auug.org.au>, 
 linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731477435; l=945;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=km3rlhnqX3L3e5tGM9lHtBkDGz74vs84O5QvGvcNq3Q=;
 b=b1Q7RSfPcsZpytS289JQq6mN7s74d5X8tq1pCZ55i6rFYYxvpDpxHymaqLU8+EA/IhvpLyWxm
 Qr1XBoOtnpCC4zGgIjJDji//eLP/BK1T0C3bsB3haTr5hHZsMHo/RQN
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When compile rtc-a4, build error as following:
ERROR: modpost: drivers/rtc/rtc-amlogic-a4: struct of_device_id is
not terminated with a NULL entry!
This commit is to fix it.

Fixes: c89ac9182ee2 ("rtc: support for the Amlogic on-chip RTC")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/rtc/rtc-amlogic-a4.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/rtc/rtc-amlogic-a4.c b/drivers/rtc/rtc-amlogic-a4.c
index 4960790c4b24..2278b4c98a71 100644
--- a/drivers/rtc/rtc-amlogic-a4.c
+++ b/drivers/rtc/rtc-amlogic-a4.c
@@ -445,6 +445,7 @@ static const struct of_device_id aml_rtc_device_id[] = {
 		.compatible = "amlogic,a5-rtc",
 		.data = &a5_rtc_config,
 	},
+	{ }
 };
 MODULE_DEVICE_TABLE(of, aml_rtc_device_id);
 

---
base-commit: eb4ffa40010472dffdc276da307161545aab45a3
change-id: 20241113-fix_a4_rtc-f250f66cbb11

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

