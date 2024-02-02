From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 03 Feb 2024 07:01:54 +0800
Subject: [PATCH 1/3] usb: dwc3: handle return value of clk_get_rate()
 correctly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240203-hisi-dwc3-v1-1-448050c7b690@outlook.com>
References: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
In-Reply-To: <20240203-hisi-dwc3-v1-0-448050c7b690@outlook.com>
To: Marek Vasut <marex@denx.de>, Tom Rini <trini@konsulko.com>, 
 Sean Anderson <sean.anderson@seco.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706914914; l=739;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=MtRm6I0TUIFEsPdBRn5YOjmXm923Al8xuyQ3q0v+CA4=;
 b=fNNQ8MqVY8DXKvl+W5Shf+D4GO5Gf+j1JGqJYqV0aELkn2/2MSDpbcv6j8Cam9FBwuqcY8/y3
 Keyvlzwu2BNCArmlTZwwtroczvhJ3pLmwUBmjCvCGRGh93ZNVcWc/am
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

clk_get_rate() return -ve on error, not 0. Fix it by replacing judging
NULL with IS_ERR_VALUE().

Fixes: 6bae0eb5b8bd("usb: dwc3: Calculate REFCLKPER based on reference clock")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/usb/dwc3/core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index 4b4fcd8a22..06ff68105e 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -137,7 +137,7 @@ static void dwc3_ref_clk_period(struct dwc3 *dwc)
 
 	if (dwc->ref_clk) {
 		rate = clk_get_rate(dwc->ref_clk);
-		if (!rate)
+		if (IS_ERR_VALUE(rate))
 			return;
 		period = NSEC_PER_SEC / rate;
 	} else {

-- 
2.43.0

