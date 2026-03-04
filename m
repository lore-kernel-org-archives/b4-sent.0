From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 04 Mar 2026 10:17:48 +0000
Subject: [PATCH 2/2] hwmon: (ltc4282) Add default rsense value
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260304-hwmon-ltc4282-minor-improvs-v1-2-344622924d3a@analog.com>
References: <20260304-hwmon-ltc4282-minor-improvs-v1-0-344622924d3a@analog.com>
In-Reply-To: <20260304-hwmon-ltc4282-minor-improvs-v1-0-344622924d3a@analog.com>
To: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772619475; l=1381;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1K80NKgB8MIVoZ4myHTgOKtZ/0xG3qVAlLQ5ld8hUek=;
 b=kxY5Ss5sCb/V23P159h1ab5UWHaWON3Zq3/b4JhCG6EoFGlTeOk2QyxcreQdMgYqJN3qdFQy8
 rS5MQbuZGJfB6zQQgtTDjtTNfR+lmtvqpTyVVe6Ke9vh1CSihFp4yHy
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of failing probe when the "adi,rsense-nano-ohms" firmware
property is not provided, default rsense to 1 * MICRO. This allows
the device to probe without requiring firmware properties, which
might be useful for some high level testing.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/ltc4282.c | 15 ++++++++-------
 1 file changed, 8 insertions(+), 7 deletions(-)

diff --git a/drivers/hwmon/ltc4282.c b/drivers/hwmon/ltc4282.c
index db6534e67991..53dbf904a172 100644
--- a/drivers/hwmon/ltc4282.c
+++ b/drivers/hwmon/ltc4282.c
@@ -1328,15 +1328,16 @@ static int ltc4282_setup(struct ltc4282_state *st, struct device *dev)
 	if (ret)
 		return ret;
 
+	/* default to 1 micro ohm so we can probe without FW properties */
+	st->rsense = 1 * MICRO;
 	ret = device_property_read_u32(dev, "adi,rsense-nano-ohms",
 				       &st->rsense);
-	if (ret)
-		return dev_err_probe(dev, ret,
-				     "Failed to read adi,rsense-nano-ohms\n");
-	if (st->rsense < CENTI)
-		return dev_err_probe(dev, -EINVAL,
-				     "adi,rsense-nano-ohms too small (< %lu)\n",
-				     CENTI);
+	if (!ret) {
+		if (st->rsense < CENTI)
+			return dev_err_probe(dev, -EINVAL,
+					     "adi,rsense-nano-ohms too small (< %lu)\n",
+					     CENTI);
+	}
 
 	/*
 	 * The resolution for rsense is tenths of micro (eg: 62.5 uOhm) which

-- 
2.53.0

