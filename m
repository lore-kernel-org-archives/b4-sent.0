From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 12:21:59 +0300
Subject: [PATCH] watchdog: arm_twd: Protect the clock snapshot until
 notifier registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-arm-twd-clock-notifier-v1-1-62933570ae27@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CMBBA4auQWTsJbQpGr2Jc4HQK409rplVJC
 He3yvJbvLdAZhXOcGwWUH5LlhQrzK4BmoY4MoqvBtva3hjrcNAHlo9Huie6YUxFgrCi25Pxh45
 9GxzU+KkcZP6PT+fN+XW5MpXfDdb1C5QDF3B6AAAA
X-Change-ID: 20261124-arm-twd-clock-notifier-47c1d95ed0f4
To: Guenter Roeck <linux@roeck-us.net>, linux-watchdog@vger.kernel.org
Cc: Wim Van Sebroeck <wim@linux-watchdog.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795512118; l=2819;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=p2sYExYr/jO4sa/Pzc9YiL7jgTYBz7CEinmU5GG86Do=;
 b=VKSH9DQH5NzG5wXNQbbOG5bM9NbRQJgeAnhBSlyzzi6f4pHjXYtULw/lPg3h+b5QIcFQJ/Czw
 eEoM9dcRDujDm1+ygFz9bhuJ7EyXNGWMydoWQ6zWkzX9PVC+5WhAtZm
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A clock rate change can complete after clk_get_rate() returns but before
probe registers the clock notifier. The driver then misses that change
and keeps the old rate when programming the watchdog counter.

Take temporary rate exclusivity before reading the clock rate and release
it after registering the notifier. This protects the snapshot against
changes from other consumers, including changes to an ancestor clock,
until subsequent transitions can be observed. Release the protection on
the zero-rate and notifier registration error paths as well.

Fixes: 52d91ea73e05 ("watchdog: Add ARM TWD (MPCore private) watchdog driver")
Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
This is a single-fix follow-up against watchdog-next, rather than a new
revision of the accepted driver series. A rate change from another CCF
consumer can finish between the rate snapshot and notifier installation.
Temporary rate exclusivity closes that handoff without retaining the CCF
prepare lock or holding the watchdog mutex across a CCF call.

Validation: the old and fixed clock-backed probe branches, actual CCF
functions and the actual TWD notifier were exercised with 25 deterministic
interleaving/unwind cases under both GCC and Clang ASan/UBSan. The full
modified driver also builds as an ARM module with W=1, with all imports
resolved. These are offline checks; no changing-clock hardware test is
claimed. The separate maximum-timeout policy for future faster clock
rates is unchanged.
---
 drivers/watchdog/arm_twd_wdt.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/watchdog/arm_twd_wdt.c b/drivers/watchdog/arm_twd_wdt.c
index f83770109..aa974da23 100644
--- a/drivers/watchdog/arm_twd_wdt.c
+++ b/drivers/watchdog/arm_twd_wdt.c
@@ -553,13 +553,21 @@ static int twd_wdt_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(clk), "failed to get clock\n");
 
 	if (clk) {
+		/* Keep the rate snapshot stable until its notifier is installed. */
+		ret = clk_rate_exclusive_get(clk);
+		if (ret)
+			return dev_err_probe(dev, ret, "failed to protect clock rate\n");
+
 		wdt->rate = clk_get_rate(clk);
-		if (!wdt->rate)
+		if (!wdt->rate) {
+			clk_rate_exclusive_put(clk);
 			return dev_err_probe(dev, -EINVAL, "clock rate is zero\n");
+		}
 
 		wdt->max_rate = wdt->rate;
 		wdt->clk_nb.notifier_call = twd_wdt_clk_notify;
 		ret = devm_clk_notifier_register(dev, clk, &wdt->clk_nb);
+		clk_rate_exclusive_put(clk);
 		if (ret)
 			return dev_err_probe(dev, ret, "failed to register clock notifier\n");
 	} else {

---
base-commit: 43495d289b7cc30f95791fb7cd7999d766b659b8
change-id: 20261124-arm-twd-clock-notifier-47c1d95ed0f4

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

