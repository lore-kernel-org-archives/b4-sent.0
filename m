From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:22 +0800
Subject: [PATCH 07/21] media: i2c: it6625: drop redundant parentheses in
 status helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-7-78d72d7886a5@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1911;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=+aDCjoF5sVqbtnaUoN2TsLy07b6ldMFq1pFd16oDI2M=;
 b=2QSZvAH8tBYZg+k3tWili1X17Y2muq02CBmcSVjNDP9t3FK9QHq5hn5ylWPmQLy0lBL2sKE//
 i3E12ug0aYyCL8f+XPlY7QAY66gh6IBDZoG9E0uXJiRjLu45x8mDd8e
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
index 9077f66187c647f85e41e571ff0d52e5e2ffdfdf..62fabf6169fc24364e484cf573b0fc1af174afbb 100644
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

