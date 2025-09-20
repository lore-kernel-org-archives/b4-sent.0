From: Sven Peter <sven@kernel.org>
Date: Sat, 20 Sep 2025 12:28:03 +0000
Subject: [PATCH] usb: typec: tipd: Fix error handling in
 cd321x_read_data_status
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-tipd-fix-v1-1-49886d4f081d@kernel.org>
X-B4-Tracking: v=1; b=H4sIANKdzmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyMD3ZLMghTdtMwKXYNkU4M0yzRLy0TTRCWg8oKiVKAw2Kjo2NpaAHd
 1ZmJaAAAA
X-Change-ID: 20250920-tipd-fix-0c50f9f99a5a
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dan Carpenter <dan.carpenter@linaro.org>, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2170; i=sven@kernel.org;
 h=from:subject:message-id; bh=0b5NmMOnbDP9MtwNwBgV04ka112u6zlExhIdniRtJx0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8a5udctpXkWrnv+976tQobui80y03UL3mz2e5jNy3GsZ
 j7/wafMHaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJhL9n+J8vmfzsVXKd8sSH
 PmdlI59ci/y1asWhlR8maLhtLQ++9+IZw0/GbzeLePfPtHoz44mmnf98OxmmlTtcT+16GnBwi6k
 i8xI2AA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Right now cd321x_read_data_status always returns true even if it
encounters any errors: tps6598x_read_data_status returns a boolean but
we treated it as an errno and then we have a bunch of dev_errs in case
tps6598x_block_read fails but just continue along and return true.
Fix that to correctly report errors to the callee.

Reported-by: Dan Carpenter <dan.carpenter@linaro.org>
Closes: https://lore.kernel.org/linux-usb/aMvWJo3IkClmFoAA@stanley.mountain/
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index 2b1049c9a6f3c4300f4a25a97fe502c47e82a134..d0c86347251c5cc19a9b377550c00c27966f8329 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -577,30 +577,36 @@ static bool cd321x_read_data_status(struct tps6598x *tps)
 	int ret;
 
 	ret = tps6598x_read_data_status(tps);
-	if (ret < 0)
+	if (!ret)
 		return false;
 
 	if (tps->data_status & TPS_DATA_STATUS_DP_CONNECTION) {
 		ret = tps6598x_block_read(tps, TPS_REG_DP_SID_STATUS,
 				&cd321x->dp_sid_status, sizeof(cd321x->dp_sid_status));
-		if (ret)
+		if (ret) {
 			dev_err(tps->dev, "Failed to read DP SID Status: %d\n",
 				ret);
+			return false;
+		}
 	}
 
 	if (tps->data_status & TPS_DATA_STATUS_TBT_CONNECTION) {
 		ret = tps6598x_block_read(tps, TPS_REG_INTEL_VID_STATUS,
 				&cd321x->intel_vid_status, sizeof(cd321x->intel_vid_status));
-		if (ret)
+		if (ret) {
 			dev_err(tps->dev, "Failed to read Intel VID Status: %d\n", ret);
+			return false;
+		}
 	}
 
 	if (tps->data_status & CD321X_DATA_STATUS_USB4_CONNECTION) {
 		ret = tps6598x_block_read(tps, TPS_REG_USB4_STATUS,
 				&cd321x->usb4_status, sizeof(cd321x->usb4_status));
-		if (ret)
+		if (ret) {
 			dev_err(tps->dev,
 				"Failed to read USB4 Status: %d\n", ret);
+			return false;
+		}
 	}
 
 	return true;

---
base-commit: a4e143636d5def935dd461539b67b61287a8dfef
change-id: 20250920-tipd-fix-0c50f9f99a5a

Best regards,
-- 
Sven Peter <sven@kernel.org>

