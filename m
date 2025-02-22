From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 22 Feb 2025 16:56:46 +0000
Subject: [PATCH 1/4] soc: apple: rtkit: Add APPLE_RTKIT_PWR_STATE_INIT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-apple-soc-misc-v1-1-1a3af494a48a@svenpeter.dev>
References: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
In-Reply-To: <20250222-apple-soc-misc-v1-0-1a3af494a48a@svenpeter.dev>
To: Alyssa Rosenzweig <alyssa@rosenzweig.io>, Janne Grunau <j@jannau.net>, 
 Sven Peter <sven@svenpeter.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1222; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=Bzvx04lIOmxyPohnaPEhCN5D4RKIiEvPi9Robq/Ze9c=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/ouxo/rVmyVvXBlx/HL/Axro6/Jf2Ssqfr/+Ipx6jHuu
 KDniVYSHaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJCGxhZHh0ra7t9n/1E1ll
 755zRtot3xw8K+ajqgR70srn+008qgUZ/tcXvJuyb+fM1yfjOO95aXLUX8/v25pepLcgoOz4/13
 vnRgB
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

This state is needed to wake the dcp IOP after m1n1 shut it down.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/soc/apple/rtkit.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/soc/apple/rtkit.c b/drivers/soc/apple/rtkit.c
index 2f5f878bf899..be0d08861168 100644
--- a/drivers/soc/apple/rtkit.c
+++ b/drivers/soc/apple/rtkit.c
@@ -12,6 +12,7 @@ enum {
 	APPLE_RTKIT_PWR_STATE_IDLE = 0x201, /* sleeping, retain state */
 	APPLE_RTKIT_PWR_STATE_QUIESCED = 0x10, /* running but no communication */
 	APPLE_RTKIT_PWR_STATE_ON = 0x20, /* normal operating state */
+	APPLE_RTKIT_PWR_STATE_INIT = 0x220, /* init after starting the coproc */
 };
 
 enum {
@@ -898,7 +899,7 @@ int apple_rtkit_wake(struct apple_rtkit *rtk)
 	 * Use open-coded apple_rtkit_set_iop_power_state since apple_rtkit_boot
 	 * will wait for the completion anyway.
 	 */
-	msg = FIELD_PREP(APPLE_RTKIT_MGMT_PWR_STATE, APPLE_RTKIT_PWR_STATE_ON);
+	msg = FIELD_PREP(APPLE_RTKIT_MGMT_PWR_STATE, APPLE_RTKIT_PWR_STATE_INIT);
 	ret = apple_rtkit_management_send(rtk, APPLE_RTKIT_MGMT_SET_IOP_PWR_STATE,
 					  msg);
 	if (ret)

-- 
2.34.1

