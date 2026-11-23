From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 23 Nov 2026 00:46:28 +0000
Subject: [PATCH] firmware: samsung: acpm: Don't use pdev after putting it
 in acpm_get_by_node()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-exynos-acpm-put-v1-1-447097ce7998@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOOMA2sC/yXMQQ6CMBBA0auQWTsJUwyIVzEs2jrKmFCaDhAI4
 e5UXb7F/zsoJ2GFe7FD4kVUxpBBlwJ8b8ObUZ7ZYEpTE5kKed3CqGh9HDDOE7obuZaa6mqphlz
 FxC9Zf8dH97fO7sN++m7gOE6xNCuvcwAAAA==
X-Change-ID: 20261123-exynos-acpm-put-b81b91734a16
To: tudor.ambarus@linaro.org, krzk@kernel.org, peter.griffin@linaro.org
Cc: alim.akhtar@samsung.com, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795394787; l=1475;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=bChsoGwuOPp0ZcQo4sMwjJk0mSKlHPd8ZsaLm0M8RC4=;
 b=dlh7WxPdsQpKUOCbkeS09eaORPYYJsWQ32yurBgjgsxUeyfMzWXuLHNHLFAClztR21aOZnvPM
 egBpPS8BVPoCjv0hliZYoEw/AwDhzC89wp3oPh2bTv7J+55+XXipdwu
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When device_link_add() fails, acpm_get_by_node() drops the reference to
the ACPM platform device and only then reads its driver to drop the
module reference:

	platform_device_put(pdev);
	module_put(pdev->dev.driver->owner);

The reference from of_find_device_by_node() is what keeps pdev around
here, so pdev must not be used after the put.

Drop the module reference before the device reference, as
acpm_handle_put() already does.

Found with a static analysis tool and checked by hand.

Fixes: a88927b534ba ("firmware: add Exynos ACPM protocol driver")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 (W=1). I don't have the hardware.
---
 drivers/firmware/samsung/exynos-acpm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/firmware/samsung/exynos-acpm.c b/drivers/firmware/samsung/exynos-acpm.c
index a575caf871b9..15d2f708b0c7 100644
--- a/drivers/firmware/samsung/exynos-acpm.c
+++ b/drivers/firmware/samsung/exynos-acpm.c
@@ -816,8 +816,8 @@ static struct acpm_handle *acpm_get_by_node(struct device *dev,
 		dev_err(&pdev->dev,
 			"Failed to create device link to consumer %s.\n",
 			dev_name(dev));
-		platform_device_put(pdev);
 		module_put(pdev->dev.driver->owner);
+		platform_device_put(pdev);
 		return ERR_PTR(-EINVAL);
 	}
 



