From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:24 +0800
Subject: [PATCH 09/21] media: i2c: it6625: tidy CEC buffer init and a
 continuation line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-9-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1973;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=NnYGUJlmTkGxYwl+rsslEcp8n5vm8G5JSLjxvFJvsgU=;
 b=4kD8/euat28my7nYzQPmlRvoviWk6fzS2lcv8rAEUThn/3yb6V9bA+QKQ62+EAcX821iZbcKa
 +ku0+nNYZrbCmlQs1LUeTCXFBctn3OL4cMGCiHMttZcbsAqNNXhrHlP
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it6625_hpd_delayed_work(): wrap the container_of() assignment after
'=' instead of splitting the argument list mid-parenthesis.

it6625_cec_adap_enable(): assign the cmds[] buffer at declaration
instead of two separate statements, matching the pattern already used
elsewhere in this file.

it6625_cec_adap_log_addr(): add the missing spaces inside the cmds[]
initializer's braces.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 9b1d9edca8f383f4f55918bda259a1b053d7f41b..bc6b0a9a0bb005b30983a30f8ca685f885ab78c6 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -757,8 +757,8 @@ static void it6625_enable_hpd(struct it6625 *it6625)
 
 static void it6625_hpd_delayed_work(struct work_struct *work)
 {
-	struct it6625 *it6625 = container_of(work,
-			struct it6625, hpd_delayed_work.work);
+	struct it6625 *it6625 =
+		container_of(work, struct it6625, hpd_delayed_work.work);
 	int val = 0;
 
 	guard(mutex)(&it6625->it6625_lock);
@@ -980,10 +980,8 @@ static void it6625_initial_setup(struct it6625 *it6625)
 static int it6625_cec_adap_enable(struct cec_adapter *adap, bool enable)
 {
 	struct it6625 *it6625 = adap->priv;
-	u8 cmds[2];
+	u8 cmds[2] = { CMD_SET_CEC_ENABLE, enable ? 1 : 0 };
 
-	cmds[0] = CMD_SET_CEC_ENABLE;
-	cmds[1] = enable ? 1 : 0;
 	guard(mutex)(&it6625->it6625_lock);
 	it6625_write_command(it6625, cmds, sizeof(cmds));
 
@@ -1009,7 +1007,7 @@ static void it6625_cec_reset_la(struct it6625 *it6625, bool keep_enabled)
 static int it6625_cec_adap_log_addr(struct cec_adapter *adap, u8 log_addr)
 {
 	struct it6625 *it6625 = adap->priv;
-	u8 cmds[2] = {CMD_SET_CEC_LA, log_addr};
+	u8 cmds[2] = { CMD_SET_CEC_LA, log_addr };
 
 	dev_dbg(it6625->dev, "%s: la=%d", __func__, log_addr);
 

-- 
2.34.1

