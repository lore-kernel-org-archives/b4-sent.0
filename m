From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 10:56:17 +0000
Subject: [PATCH] pwm: Don't dereference the chip after put_device() in
 __pwm_put()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-pwm-v1-1-adeff0cc366a@gmail.com>
X-B4-Tracking: v=1; b=H4sIANDV/moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NL3YLyXN2k1DSLJCMDS0Pj1CQloMqCotS0zAqwKdGxEH5xaVJWanI
 JSKtSbS0AMCcNyWcAAAA=
X-Change-ID: 20261119-pwm-bef8b20913eb
To: ukleinek@kernel.org, m.wilczynski@samsung.com
Cc: linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795085777; l=1758;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=aTL9kEFJ/2KUWaQPI32vzjKcn/Y5nqsqx2zxlXKIavY=;
 b=OdjzFDiKHlRc+nctzng5NG3aU5iRyCpyMb/R77YV+LChxy9Piz3sCrn3a1WCS6uS4Z/rR1F2H
 lMPWEpVoIHeBXZhGgWucsvqa14Poj4Zef660V/6MJNnnJqEoOYa6nsI
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

__pwm_put() drops the chip reference the consumer took and then reads the
chip to drop the module reference:

	put_device(&chip->dev);
	module_put(chip->owner);

A consumer takes both references in pwm_device_request()
(try_module_get(chip->owner) and get_device(&chip->dev)). The chip's base
reference is released by pwmchip_put(), not by pwmchip_remove(), so a
consumer can still hold a pwm after the provider has removed and put the
chip. When that consumer finally calls pwm_put(), the put_device() here
drops the last reference, pwmchip_release() frees the chip, and
module_put(chip->owner) then reads the freed chip.

Read chip->owner into a local before put_device() and use that.

Found with a static analysis tool and checked by hand.

Fixes: 4c56b1434b81 ("pwm: Add a struct device to struct pwm_chip")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on x86_64 (W=1 and sparse, no new warnings). I don't have
the hardware.
---
 drivers/pwm/core.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pwm/core.c b/drivers/pwm/core.c
index 4c6d716e5fde..8988a7dbe5b1 100644
--- a/drivers/pwm/core.c
+++ b/drivers/pwm/core.c
@@ -2020,6 +2020,7 @@ EXPORT_SYMBOL_GPL(pwm_get);
 static void __pwm_put(struct pwm_device *pwm)
 {
 	struct pwm_chip *chip = pwm->chip;
+	struct module *owner = chip->owner;
 
 	/*
 	 * Trigger a warning if a consumer called pwm_put() twice.
@@ -2038,7 +2039,7 @@ static void __pwm_put(struct pwm_device *pwm)
 
 	put_device(&chip->dev);
 
-	module_put(chip->owner);
+	module_put(owner);
 }
 
 /**



