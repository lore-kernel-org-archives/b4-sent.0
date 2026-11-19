From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 19:28:02 +0000
Subject: [PATCH v2] pwm: Drop the module reference before the chip in
 __pwm_put()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-pwm-v2-1-fe761df4f272@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMFN/2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NL3YLyXF3jlGSLlCQDcyMzU0MloMqCotS0zAqwKdGxEH5xaVJWanI
 JSKtSbS0Aadf4RmcAAAA=
X-Change-ID: 20261119-pwm-3dc8db072651
To: ukleinek@kernel.org, m.wilczynski@samsung.com
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795116482; l=1837;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=jU7pi4yuE2f3TtWrb3aU0gY1rBGzqQsso5D2Sa20T0U=;
 b=b9OLKs/Bm6WhAwXYM7jiPZyYPyKDjRH2gs7/gaItPByrCW8qwcHFbFkVrP+1DmEBTZOsL1UBZ
 yMvlSpjEv5cCTAJNKpgEsDoCOXQPr3pGLSzy9/aO6w0r13cYeOhjyip
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

Call module_put() before put_device(). This is safe because the chip is
released by pwmchip_release() in the PWM core, not by code in the
provider module.

Found with a static analysis tool and checked by hand.

Fixes: 4c56b1434b81 ("pwm: Add a struct device to struct pwm_chip")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Changes in v2:
- Call module_put() before put_device() instead of reading chip->owner
  into a local first (Uwe).

Compile tested on x86_64 (W=1 and sparse, no new warnings). I don't have
the hardware.

v1: https://lore.kernel.org/linux-pwm/20261119-pwm-v1-1-adeff0cc366a@gmail.com/
---
 drivers/pwm/core.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/pwm/core.c b/drivers/pwm/core.c
index 4c6d716e5fde..4e8dba089261 100644
--- a/drivers/pwm/core.c
+++ b/drivers/pwm/core.c
@@ -2036,9 +2036,9 @@ static void __pwm_put(struct pwm_device *pwm)
 
 	pwm->label = NULL;
 
-	put_device(&chip->dev);
-
 	module_put(chip->owner);
+
+	put_device(&chip->dev);
 }
 
 /**



