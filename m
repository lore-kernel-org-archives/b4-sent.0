From: "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
Date: Fri, 10 Jan 2025 00:37:47 +0300
Subject: [PATCH v3 1/4] input: cyttsp5: improve error handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-nekocwd-upstreaming-cyttsp5-v3-1-b33659c8effc@gmail.com>
References: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
In-Reply-To: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 James Hilliard <james.hilliard1@gmail.com>, 
 "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1450;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=9Z6oGtzENjF2jSzhfi6RSWXqg4Z8w0BD0egfwtWSBQA=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNIbHM88XHJFR22DgUL64aV7lrwXUfHZmbJP2WtprfCzG
 ucpjxf/6yhlYRDjYpAVU2Sx2egxWyw/XHLStKcKMHNYmUCGMHBxCsBEWnYzMnxvzQiQe7ZV9rh+
 RfBeh5CSuW9tLiT//73viaDDdKvY7QWMDF9ubD38/XJF22M117bLGycLCTtF3pnKFGPpHmW43Jn
 5DRcA
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Improved error messages: added command name to timeout reports

Co-developed-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: Vasiliy Doylov (NekoCWD) <nekodevelopper@gmail.com>
---
 drivers/input/touchscreen/cyttsp5.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/cyttsp5.c b/drivers/input/touchscreen/cyttsp5.c
index eafe5a9b89648475ff7435566eb38c094d66a473..ef74b4f190351b99c0722b38ae5fa491a4087ffe 100644
--- a/drivers/input/touchscreen/cyttsp5.c
+++ b/drivers/input/touchscreen/cyttsp5.c
@@ -559,7 +559,7 @@ static int cyttsp5_hid_output_get_sysinfo(struct cyttsp5 *ts)
 	rc = wait_for_completion_interruptible_timeout(&ts->cmd_done,
 						msecs_to_jiffies(CY_HID_OUTPUT_GET_SYSINFO_TIMEOUT_MS));
 	if (rc <= 0) {
-		dev_err(ts->dev, "HID output cmd execution timed out\n");
+		dev_err(ts->dev, "HID output get sysinfo cmd execution timed out\n");
 		rc = -ETIMEDOUT;
 		return rc;
 	}
@@ -633,7 +633,7 @@ static int cyttsp5_hid_output_bl_launch_app(struct cyttsp5 *ts)
 	rc = wait_for_completion_interruptible_timeout(&ts->cmd_done,
 				msecs_to_jiffies(CY_HID_OUTPUT_TIMEOUT_MS));
 	if (rc <= 0) {
-		dev_err(ts->dev, "HID output cmd execution timed out\n");
+		dev_err(ts->dev, "HID output bl launch app cmd execution timed out\n");
 		rc = -ETIMEDOUT;
 		return rc;
 	}

-- 
2.47.1

