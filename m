From: Vishnu Razdan <vrazdan@openai.com>
Date: Mon, 24 Aug 2026 23:58:00 -0700
Subject: [PATCH] hwmon: (pmbus) Clear generic status alarms with
 CLEAR_FAULTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-vrazdan-pmbus-status-word-b4-v1-1-2606ecd0c029@openai.com>
X-B4-Tracking: v=1; b=H4sIAPc8jWoC/yWMwQ6CMBBEf4Xs2U2AVCH+ivGwpavUhEJ2WzQS/
 t1WTpM3M3kbKItnhWu1gfDq1c8hQ3OqYBgpPBm9ywxt3V7qvjW4Cn0dBVwmmxQ1UszxnsWhNWh
 r15i+P3edaSArFuGH//z1t/vBmuyLh1ic5WFJGa1QGMZSHda0aBSmCcsK+/4DMTocPaYAAAA=
X-Change-ID: 20260824-vrazdan-pmbus-status-word-b4-b0d148857741
To: linux@roeck-us.net
Cc: vrazdan@openai.com, linux-hwmon@vger.kernel.org, 
 linux-kernel@vger.kernel.org, vikash.chandola@linux.intel.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787641169; l=2169;
 i=vrazdan@openai.com; s=io-wq-kernel-20260811; h=from:subject:message-id;
 bh=alnznPhZtLYc/QrJKqWIsTFzP2+B2p3+SqAtTUiocw4=;
 b=XEA92ojJF0fXsiH2Wt20uaU8sx2/6fgUSc2w/Wq51aeTRqP9rLmhIYYAHMym5/972zJOcY/kH
 +m66muWcXo6AQHtut8QLBgh3YPqCcu+znuS7YQ81eLcCFYc6h9jk0XE
X-Developer-Key: i=vrazdan@openai.com; a=ed25519;
 pk=45vHW8D/KId5RtsP3Qx7zMcNpgDwEvCnL5uAw0KzuS0=
X-Endpoint-Received: by B4 Relay for vrazdan@openai.com/io-wq-kernel-20260811 with auth_id=937
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some hwmon alarms fall back to STATUS_WORD summary bits when no
individual limit alarm is available. On PMBus 1.2 and newer devices,
pmbus_get_boolean() acknowledges these alarms with the same byte-data
write used for detailed status registers. For example, PB_STATUS_INPUT
is 0x2000, so it is truncated to zero when passed to
_pmbus_write_byte_data(). The resulting write cannot acknowledge the
input alarm.

PMBus 1.3 Part II, sections 10.2.4 and 10.2.5, excludes ordinary
STATUS_BYTE and STATUS_WORD summary bits from individual clearing.
Their summary bits clear when the underlying status bits clear, so
changing this to a word-data write would not fix the generic input
alarm either.

Use the existing page CLEAR_FAULTS path for generic STATUS_WORD
alarms, including devices whose status accessor uses STATUS_BYTE.
Keep individual byte writes for detailed status registers on PMBus
1.2 and newer devices. As with the existing older-device fallback,
CLEAR_FAULTS can clear other latched status; an active condition can
reassert its status.

Fixes: 35f165f08950 ("hwmon: (pmbus) Clear pmbus fault/warning bits after read")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Vishnu Razdan <vrazdan@openai.com>
---
 drivers/hwmon/pmbus/pmbus_core.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index 806c9a4913bb0..5f69c1420b4e1 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -1275,7 +1275,9 @@ static int pmbus_get_boolean(struct i2c_client *client, struct pmbus_boolean *b,
 
 	regval = status & mask;
 	if (regval) {
-		if (data->revision >= PMBUS_REV_12) {
+		/* Generic STATUS_WORD alarms are not individually clearable. */
+		if (data->revision >= PMBUS_REV_12 &&
+		    reg != PMBUS_STATUS_WORD) {
 			ret = _pmbus_write_byte_data(client, page, reg, regval);
 			if (ret)
 				return ret;

---
base-commit: 83a16909eb64360fd0659f7970665272cdbe65a1
change-id: 20260824-vrazdan-pmbus-status-word-b4-b0d148857741

Best regards,
--  
Vishnu Razdan <vrazdan@openai.com>

