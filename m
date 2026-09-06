From: Miles Krause <mileskrause5200@gmail.com>
Date: Sun, 06 Sep 2026 15:11:37 -0400
Subject: [PATCH] leds: max77705: fix fwnode reference leak in
 max77705_add_led()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-leds-max77705-fwnode-leak-v1-1-eba6822529fd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOi6nWoC/x2MwQqDMBAFf0X23IUoamp/pXgIm6cu1VgSUEH8d
 4PHGZg5KSEqEn2KkyI2TbqGDOWrIJlcGMHqM1NlqtZ0puUZPvHiDmutaXjYw+qRpftxKR51J5D
 mLZT7f8Sgx/P+9td1A0pFE3prAAAA
To: Chanwoo Choi <cw00.choi@samsung.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Dzmitry Sankouski <dsankouski@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-leds@vger.kernel.org, 
 Miles Krause <mileskrause5200@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788721897; l=2511;
 i=mileskrause5200@gmail.com; s=20260906; h=from:subject:message-id;
 bh=uWLiKNxt5uyo3KP1HFhOtzgKNbhHZtcLBJPxpW7G2g8=;
 b=ZvEU3/DJpCoqDJBpko40f9/7MTbBMNSzC3WwHVGJHzdQXl5AypBkKKB608YtWIT3eb/FRPHhJ
 h8oxhhAUz1rD0D9tfrHFXQVclZyw3mfOj76Mf7X3Hoh38E3eupMEmh6
X-Developer-Key: i=mileskrause5200@gmail.com; a=ed25519;
 pk=zcIfq4TGtPwMRJUW6WsbE2zLHvOMwk6ZyT/CGd6XzyI=
X-Endpoint-Received: by B4 Relay for mileskrause5200@gmail.com/20260906 with auth_id=1010
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

max77705_add_led() iterates over the multicolor LED's child nodes with
fwnode_for_each_child_node() and returns directly from inside the loop
when parsing a child fails:

	fwnode_for_each_child_node(np, child) {
		ret = max77705_parse_subled(dev, child, &info[i]);
		if (ret < 0)
			return ret;
		...
	}

The iterator holds a reference on the current child for the duration of
each iteration: fwnode_get_next_child_node() takes a reference on the
node it returns and only drops the previous one when it is called again
(for the OF backend that is the of_node_put(prev) in
of_get_next_status_child()).  Returning from inside the loop skips that
final call, so the reference taken for the child that failed to parse is
never released.

max77705_parse_subled() rejects a missing, zero or out-of-range "reg"
property and propagates errors from reading "color", so a malformed
device tree is enough to leak a device_node reference.

Use fwnode_for_each_child_node_scoped() instead, which releases the
reference on every exit path, and drop the now unused 'child'
declaration.  max77705_led_probe() already uses the equivalent
device_for_each_child_node_scoped() for the outer loop.

Fixes: aebb5fc9a0d8 ("leds: max77705: Add LEDs support")
Signed-off-by: Miles Krause <mileskrause5200@gmail.com>
---
 drivers/leds/leds-max77705.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/leds/leds-max77705.c b/drivers/leds/leds-max77705.c
index 1e2054c1bf80..4fd803c95989 100644
--- a/drivers/leds/leds-max77705.c
+++ b/drivers/leds/leds-max77705.c
@@ -160,7 +160,6 @@ static int max77705_add_led(struct device *dev, struct regmap *regmap, struct fw
 	struct max77705_led *led;
 	struct led_classdev *cdev;
 	struct mc_subled *info;
-	struct fwnode_handle *child;
 	struct led_init_data init_data = {};
 
 	led = devm_kzalloc(dev, sizeof(*led), GFP_KERNEL);
@@ -191,7 +190,7 @@ static int max77705_add_led(struct device *dev, struct regmap *regmap, struct fw
 		cdev->brightness_set_blocking = max77705_led_brightness_set_multi;
 		cdev->blink_set = max77705_rgb_blink;
 
-		fwnode_for_each_child_node(np, child) {
+		fwnode_for_each_child_node_scoped(np, child) {
 			ret = max77705_parse_subled(dev, child, &info[i]);
 			if (ret < 0)
 				return ret;

---
base-commit: 88405f0ad1d5c680afe3ea0ce9345fa9e1deaac8
change-id: 20260906-leds-max77705-fwnode-leak-1cde49cec58c

Best regards,
-- 
Miles Krause <mileskrause5200@gmail.com>

