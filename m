From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Mon, 07 Apr 2025 13:48:49 +0200
Subject: [PATCH] rtc: sd2405al: Add I2C address.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250407-rtc-sd2405al-i2c-addr-v1-1-efdd951952c0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKC782cC/x3MwQqDMAyA4VeRnA3UzM7qq4iH0mRbYFRJRQbiu
 694/A7/f0IRUykwNSeYHFp0zRVd20D6xPwWVK4GcuRd7wa0PWFh6p2PX1RKGJkNHyOxDxL8c2C
 o7Wby0t/9nZfr+gMVtME4ZwAAAA==
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-rtc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744026537; l=976;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=fg5GX8rA+Q5pAy0F9ekX3Q4r3NUci+f2g8fC+4fI6IQ=;
 b=lS+9qPiYe02kBjoBsCue2i0H/hxmCMMXIY0GYgeI2sHiYyuUljLEUfzLHKYX8CDQ7BE/FCiCA
 x7D//v3z2FPCZMzTj4MHPk1V9764M88WXK7xfKcZlAyes49iBNqImBe
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It is common to include the I2C address of the device in the source
file.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
It is common to include the I2C address of the device in the source file.
---
 drivers/rtc/rtc-sd2405al.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/rtc/rtc-sd2405al.c b/drivers/rtc/rtc-sd2405al.c
index 00c3033e8079..708ea5d964de 100644
--- a/drivers/rtc/rtc-sd2405al.c
+++ b/drivers/rtc/rtc-sd2405al.c
@@ -5,7 +5,9 @@
  * Datasheet:
  * https://image.dfrobot.com/image/data/TOY0021/SD2405AL%20datasheet%20(Angelo%20v0.1).pdf
  *
- * Copyright (C) 2024 Tóth János <gomba007@gmail.com>
+ * I2C slave address: 0x32
+ *
+ * Copyright (C) 2024-2025 Tóth János <gomba007@gmail.com>
  */
 
 #include <linux/bcd.h>

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250407-rtc-sd2405al-i2c-addr-392d58e8567d

Best regards,
-- 
Tóth János <gomba007@gmail.com>

