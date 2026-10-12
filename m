From: Igor Velkov <iav@iav.lv>
Date: Mon, 12 Oct 2026 03:46:56 +0300
Subject: [PATCH v2 1/2] watchdog: orion_wdt: load the pretimeout counter on
 Armada 370/XP start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-orion-wdt-suspend-v2-1-f13cf71443ba@iav.lv>
References: <20261012-orion-wdt-suspend-v2-0-f13cf71443ba@iav.lv>
In-Reply-To: <20261012-orion-wdt-suspend-v2-0-f13cf71443ba@iav.lv>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Chris Packham <chris.packham@alliedtelesis.co.nz>, 
 Gregory CLEMENT <gregory.clement@bootlin.com>, 
 linux-watchdog@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1389; i=iav@iav.lv;
 h=from:subject:message-id; bh=HrWBFE8j0tmsNO1GiKYgGURCmZKbChpzPiL1sI0Aof4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFln9NiDldbzBq5+1n64/b5w6IMrjZe+9nFZfE3/13VKj
 5Xpx7vvHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAitgGMDLtuxMyqT1qparv5
 onC9Y/qpS4WrGztf+9kb7yhc9/b36mBGhp1apmvimUwrQpmmPDHJXBXcndkV6s84r/CSfJan3Md
 kTgA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

armada370_start() enables TIMER1 for the pretimeout but, unlike
armada375_start(), does not load its counter, so TIMER1 runs down from
whatever value it holds and the pretimeout can fire early. Of the boards
that use armada370_start(), only Armada XP and 98DX3236 describe the
pretimeout interrupt in their device tree.

Load TIMER1 on start the same way armada375_start() does.

Fixes: 7a6b3d8a432d ("watchdog: orion_wdt: support pretimeout on Armada-XP")
Link: https://sashiko.dev/#/patchset/20261012-orion-wdt-suspend-v1-1-1676cb79e29e@iav.lv?part=1
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/watchdog/orion_wdt.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/watchdog/orion_wdt.c b/drivers/watchdog/orion_wdt.c
index 5d56e93f0406..ef64e3730001 100644
--- a/drivers/watchdog/orion_wdt.c
+++ b/drivers/watchdog/orion_wdt.c
@@ -232,6 +232,9 @@ static int armada370_start(struct watchdog_device *wdt_dev)
 	/* Set watchdog duration */
 	writel(dev->clk_rate * wdt_dev->timeout,
 	       dev->reg + dev->data->wdt_counter_offset);
+	if (dev->wdt.info->options & WDIOF_PRETIMEOUT)
+		writel(dev->clk_rate * (wdt_dev->timeout - wdt_dev->pretimeout),
+		       dev->reg + TIMER1_VAL_OFF);
 
 	/* Clear the watchdog expiration bit */
 	atomic_io_modify(dev->reg + TIMER_A370_STATUS, WDT_A370_EXPIRED, 0);

-- 
2.43.0

