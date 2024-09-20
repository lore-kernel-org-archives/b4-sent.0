From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 20 Sep 2024 09:22:52 +0200
Subject: [PATCH] Input: adp5588-keys: fix check on return code
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240920-fix-adp5588-err-check-v1-1-81f6e957ef24@analog.com>
X-B4-Tracking: v=1; b=H4sIAMsi7WYC/x2MwQqDMBAFf0X23IWYdjX2V6QHja+6CCobEEH8d
 4PHgZk5KcEUib7FSYZdk65LhvJVUJy6ZQTrkJm88x/XeMd/PbgbNpEQGGYcJ8SZK0Dk3dd9kIp
 yuxmy+Hzb33Xd+3/Mo2cAAAA=
To: Andy Shevchenko <andy.shevchenko@gmail.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, 
 Michael Hennerich <michael.hennerich@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726816973; l=1120;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=3ebFrc8KerczEXKv8/mDft/LuDryKAXSlZYbDWCoHIg=;
 b=s93tWWSdAktDq+Spb4Ll1rtuu0fLfQkvB3BIhmcSzvVwZIp0w9Hd7N+zzrMSWix+1eBkE/KYX
 hEUunfOfBHHA3rjc/4YxOUMY4GG8oZSd8ovoZ8A76bJK6h14jq4EZ3B
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During adp5588_setup(), we read all the events to clear the event FIFO.
However, adp5588_read() just calls i2c_smbus_read_byte_data() which
returns the byte read in case everything goes well. Hence, we need to
explicitly check for a negative error code instead of checking for
something different than 0.

Fixes: e960309ce318 ("Input: adp5588-keys - bail out on returned error")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/input/keyboard/adp5588-keys.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/input/keyboard/adp5588-keys.c b/drivers/input/keyboard/adp5588-keys.c
index b5f4becf5cb6f..d25d63a807f23 100644
--- a/drivers/input/keyboard/adp5588-keys.c
+++ b/drivers/input/keyboard/adp5588-keys.c
@@ -620,7 +620,7 @@ static int adp5588_setup(struct adp5588_kpad *kpad)
 
 	for (i = 0; i < KEYP_MAX_EVENT; i++) {
 		ret = adp5588_read(client, KEY_EVENTA);
-		if (ret)
+		if (ret < 0)
 			return ret;
 	}
 

---
base-commit: 55bef83509f0cbe4cc54a583ac0313389dabee66
change-id: 20240920-fix-adp5588-err-check-6ee553b7b856
--

Thanks!
- Nuno Sá

