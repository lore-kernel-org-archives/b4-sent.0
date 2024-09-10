From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 10 Sep 2024 13:53:44 +0800
Subject: [PATCH] clk: Fix invalid execution of clk_set_rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240910-fix_clk-v1-1-111443baaeaa@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOfe32YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDS0MD3bTMivjknGxdc8Ok5BQjg6QUY+M0JaDqgqJUoBTYpOjY2loA901
 2lVkAAAA=
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725947627; l=1619;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=3tAKqELYhIvRcXnUoRlXXLtvnJsBHNdrLYPkwEE/zJI=;
 b=MFbnaaVvkM7y7cG1rTenn+RlC/vW4QvIC4DEqGeAHtl2HMKuRduRtutjrLqkpcqhY9gey+F/U
 sIwGXwnw06jCuqfqCuVdTeyVvBQZwriPntFkUiKwZrH2I11yHy6aOz6
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some clocks have rates that can be changed elsewhere, so add a flag
CLK_GET_RATE_NOCACHE(such as scmi_clk) to these clocks to ensure that
the real-time rate is obtained.

When clk_set_rate is called, it is returned if the request to set rate
is consistent with the current rate. Getting the current rate in
clk_set_rate returns the rate stored in clk_core. CLK_GET_RATE_NOCACHE
does not take effect here.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Some clocks have rates that can be changed elsewhere, so add a flag
CLK_GET_RATE_NOCACHE(such as scmi_clk) to these clocks to ensure that
the real-time rate is obtained.

When clk_set_rate is called, it is returned if the request to set rate
is consistent with the current rate. Getting the current rate in
clk_set_rate returns the rate stored in clk_core. CLK_GET_RATE_NOCACHE
does not take effect here.
---
 drivers/clk/clk.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 285ed1ad8a37..79b453b82528 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -2536,7 +2536,7 @@ static int clk_core_set_rate_nolock(struct clk_core *core,
 	rate = clk_core_req_round_rate_nolock(core, req_rate);
 
 	/* bail early if nothing to do */
-	if (rate == clk_core_get_rate_nolock(core))
+	if (rate == clk_core_get_rate_recalc(core))
 		return 0;
 
 	/* fail on a direct rate set of a protected provider */

---
base-commit: 2cd6543d82b9dc7b971b9b64f22ad34a1cae3076
change-id: 20240910-fix_clk-71bcd20bd33f

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

