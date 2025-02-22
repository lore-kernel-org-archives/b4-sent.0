From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 22 Feb 2025 16:56:49 +0000
Subject: [PATCH 4/4] soc: apple: rtkit: Cut syslog messages after the first
 '\0'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-apple-soc-misc-v1-4-1a3af494a48a@svenpeter.dev>
References: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
In-Reply-To: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>, Janne Grunau <j@jannau.net>, 
 Sven Peter <sven@svenpeter.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=992; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=XmS84SoHATsmW4yIuH/yX1sErrlBc4P71wmt3DfDGeo=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/ouxi+/pm7Ov+GW8XbZ0X35fc+0Wo63t2ifWBm8oPy5x
 jLvS+p1HaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJlE9iZFhQvnpuRLrzJF3+
 5Ieqeg3y7Jyb+Jd7Ha4yb1jQcCw2IIWRoaNu37tZWSsWV/06lORaflOEcalCfeqTvfdn1/md/LX
 /NxsA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Certain messages from DCP contain NUL bytes in the random data after the
NUL terminated syslog message. Since the syslog message ends with '\n'
this results in a dev_info() message terminated with two newlines and an
empty printed line in the kernel log.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/soc/apple/rtkit.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/apple/rtkit.c b/drivers/soc/apple/rtkit.c
index b7f4654c3341..595efce265ce 100644
--- a/drivers/soc/apple/rtkit.c
+++ b/drivers/soc/apple/rtkit.c
@@ -476,7 +476,7 @@ static void apple_rtkit_syslog_rx_log(struct apple_rtkit *rtk, u64 msg)
 
 	log_context[sizeof(log_context) - 1] = 0;
 
-	msglen = rtk->syslog_msg_size - 1;
+	msglen = strnlen(rtk->syslog_msg_buffer, rtk->syslog_msg_size - 1);
 	while (msglen > 0 &&
 		   should_crop_syslog_char(rtk->syslog_msg_buffer[msglen - 1]))
 		msglen--;

-- 
2.34.1

