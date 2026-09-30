From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:25 +0800
Subject: [PATCH v2 07/21] media: i2c: it6625: drop redundant parentheses in
 status helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-7-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=1911;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=hMUgQungpbvUXhPIcEyCYMEDenPhUZbplvI5NTD2M/Y=;
 b=4p861QfJr2FzWeA3OL1lEpTKQ3NGHwgCOHTW7FueOiH3uBLPSw2Alw7HbSqqcxefQY4NjMEoj
 Hb08iDNDKnQAe5mNLkRSn8ExlMOcA42HNpqwjovl+Mq6BQ2fjV4r9vd
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

is_hdmi(), hdmi_5v_power_present(), no_signal(), and audio_present()
wrap their ternary condition and true-branch bitwise-AND in
parentheses that C's operator precedence already makes unnecessary:
'<' binds tighter than '&', and '&' binds tighter than '?:'. Drop them;
behavior is unchanged.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 9382a64706919d380e8318c3139b42a4a7b2fd55..b48252a71bc1ed788de2df79c5fdaf7895f6e0c4 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -554,7 +554,7 @@ static inline bool is_hdmi(struct it6625 *it6625)
 	int val;
 
 	val = it6625_read_byte(it6625, REG_RX_STATUS);
-	return (val < 0) ? false : (val & B_RX_HDMI);
+	return val < 0 ? false : val & B_RX_HDMI;
 }
 
 static inline bool hdmi_5v_power_present(struct it6625 *it6625)
@@ -562,7 +562,7 @@ static inline bool hdmi_5v_power_present(struct it6625 *it6625)
 	int val;
 
 	val = it6625_read_byte(it6625, REG_RX_STATUS);
-	return (val < 0) ? false : (val & B_RX_5V);
+	return val < 0 ? false : val & B_RX_5V;
 }
 
 static inline bool no_signal(struct it6625 *it6625)
@@ -570,7 +570,7 @@ static inline bool no_signal(struct it6625 *it6625)
 	int val;
 
 	val = it6625_read_byte(it6625, REG_RX_STATUS);
-	return (val < 0) ? true : !(val & B_RX_STABLE);
+	return val < 0 ? true : !(val & B_RX_STABLE);
 }
 
 static inline bool audio_present(struct it6625 *it6625)
@@ -578,7 +578,7 @@ static inline bool audio_present(struct it6625 *it6625)
 	int val;
 
 	val = it6625_read_byte(it6625, REG_RX_STATUS);
-	return (val < 0) ? false : (val & B_RX_AUD_ON);
+	return val < 0 ? false : val & B_RX_AUD_ON;
 }
 
 static int get_audio_sampling_rate(struct it6625 *it6625)

-- 
2.34.1

