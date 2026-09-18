From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:23 +0800
Subject: [PATCH 08/21] media: i2c: it6625: make the audio sampling-rate
 table static const
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-8-78d72d7886a5@ite.com.tw>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1207;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=qGU/O647aZTfqdglQzVk6HPtKDWbKwtWWhBds51Ufxk=;
 b=TfBXu2AxpWb2bsLyWlvInSsVxazGkyNi7inH3WJ6fG0FNMq3IVSihhPEA4UOiuLk/PDqKom8S
 cd1DTk9Pm5MAACPnNt3OPgoHDeJhQaVk/4vAW9vTbGw5p4VvIrqTrnw
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

s_fsid_map in get_audio_sampling_rate() is a fixed lookup table
rebuilt on the stack on every call; make it static const so it's
emitted once as read-only data instead. While touching this
declaration, move it ahead of the plain int locals per reverse
fir-tree ordering.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index 62fabf6169fc24364e484cf573b0fc1af174afbb..9b1d9edca8f383f4f55918bda259a1b053d7f41b 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -583,9 +583,7 @@ static inline bool audio_present(struct it6625 *it6625)
 
 static int get_audio_sampling_rate(struct it6625 *it6625)
 {
-	int fs_id;
-	int i, freq = 0;
-	const struct fs_id_map {
+	static const struct fs_id_map {
 		u8 fs_id;
 		u32 freq;
 	} s_fsid_map[] = {
@@ -610,6 +608,8 @@ static int get_audio_sampling_rate(struct it6625 *it6625)
 		{ AUD1411K, 1411200 },
 		{ AUD1536K, 1536000 },
 	};
+	int fs_id;
+	int i, freq = 0;
 
 	if (no_signal(it6625) || !audio_present(it6625))
 		return 0;

-- 
2.34.1

