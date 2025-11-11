From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 11 Nov 2025 17:48:48 +0000
Subject: [PATCH RESEND] rtc: max31335: Fix ignored return value in
 set_alarm
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251111-max31335-handler-error-v1-1-2152457cc203@analog.com>
To: linux-rtc@vger.kernel.org
Cc: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Antoniu Miclaus <antoniu.miclaus@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762883356; l=1114;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=yZMxjkRilIU/IcTJjTLZ+cXNpd/pN79VeBziWYaCG+k=;
 b=ttzyhZJ0mCNUgOFgpX1uTN8JaIkC35I6YwJy1pkPYIN4HY4/l5Bocb+UvekaSDr1V3fNIEZGd
 VmBcFgeZMHVBCICkCV7KGQCazJ7ugdb8/1Cna7TQlqpyqix4qRyd4GH
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Return the result from regmap_update_bits() instead of ignoring it
and always returning 0.

Fixes: dedaf03b99d6 ("rtc: max31335: add driver support")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/rtc/rtc-max31335.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/rtc/rtc-max31335.c b/drivers/rtc/rtc-max31335.c
index dfb5bad3a369..23b7bf16b4cd 100644
--- a/drivers/rtc/rtc-max31335.c
+++ b/drivers/rtc/rtc-max31335.c
@@ -391,10 +391,8 @@ static int max31335_set_alarm(struct device *dev, struct rtc_wkalrm *alrm)
 	if (ret)
 		return ret;
 
-	ret = regmap_update_bits(max31335->regmap, max31335->chip->int_status_reg,
-				 MAX31335_STATUS1_A1F, 0);
-
-	return 0;
+	return regmap_update_bits(max31335->regmap, max31335->chip->int_status_reg,
+				  MAX31335_STATUS1_A1F, 0);
 }
 
 static int max31335_alarm_irq_enable(struct device *dev, unsigned int enabled)

---
base-commit: 9db26d5855d0374d4652487bfb5aacf40821c469
change-id: 20251029-max31335-handler-error-65a286c74289
--

Thanks!
- Nuno Sá
-- 
Nuno Sá <nuno.sa@analog.com>

