From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 05 Feb 2026 14:35:33 +0100
Subject: [PATCH] iio: imu: inv_icm45600: fix regulator put warning when
 probe fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260205-inv-icm45600-fix-regulator-put-warning-v1-1-314ec12512cb@tdk.com>
X-B4-Tracking: v=1; b=H4sIAKSchGkC/x2N0QrCMAwAf2Xk2UCs7UR/RfZQYqwBzUa6TWHs3
 y0+Hhx3G1RxlQrXbgOXVauO1uB46ICf2Yqg3htDoNBToIRqKyq/Y+qJ8KFfdCnLK8+j47TM+Ml
 uagXPHFOOF46cTtBik0uT/6PbsO8/W6CSXHgAAAA=
X-Change-ID: 20260205-inv-icm45600-fix-regulator-put-warning-7c45a49c4c53
To: Remi Buisson <remi.buisson@tdk.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770298539; l=2036;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=T/j7PYMV8Dkhv8t5z9e34UhoY7jumpJGzpjuK+CVlpM=;
 b=Z5aK5s1uCMhnxpxXvOFQx4RngBLnWPPbFd7r47gUprMEXOtUFxjOOHubekNAcYIa2JQcOUEw5
 5h+2Ys5JxwUAWnWBVNp6+zM9/Maj+KvQUgvX4qFwGI0vEPTRXAzPsjB
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the driver probe fails we encounter a regulator put warning
because vddio regulator is not stopped before release. The issue
comes from pm_runtime not already setup when core probe fails and
the vddio regulator disable callback is called.

Fix the issue by deleting pm_runtime check in the vddio regulator
disable callback and handing over the vddio disable management to
pm_runtime by deleting the disable remove action before setting up
pm_runtime.

Fixes: 7ff021a3faca ("iio: imu: inv_icm45600: add new inv_icm45600 driver")
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Cc: stable@vger.kernel.org
---
 drivers/iio/imu/inv_icm45600/inv_icm45600_core.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
index ab1cb7b9dba435a3280e50ab77cd16e903c7816c..18d613a025cb4f9cbb8d73f27a46fc1207f5820d 100644
--- a/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
+++ b/drivers/iio/imu/inv_icm45600/inv_icm45600_core.c
@@ -676,10 +676,6 @@ static int inv_icm45600_enable_regulator_vddio(struct inv_icm45600_state *st)
 static void inv_icm45600_disable_vddio_reg(void *_data)
 {
 	struct inv_icm45600_state *st = _data;
-	struct device *dev = regmap_get_device(st->map);
-
-	if (pm_runtime_status_suspended(dev))
-		return;
 
 	regulator_disable(st->vddio_supply);
 }
@@ -780,6 +776,8 @@ int inv_icm45600_core_probe(struct regmap *regmap, const struct inv_icm45600_chi
 	if (ret)
 		return ret;
 
+	/* hand over vddio management to pm_runtime */
+	devm_remove_action(dev, inv_icm45600_disable_vddio_reg, st);
 	pm_runtime_get_noresume(dev);
 	pm_runtime_set_autosuspend_delay(dev, 2 * USEC_PER_MSEC);
 	pm_runtime_use_autosuspend(dev);

---
base-commit: d820183f371d9aa8517a1cd21fe6edacf0f94b7f
change-id: 20260205-inv-icm45600-fix-regulator-put-warning-7c45a49c4c53

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

