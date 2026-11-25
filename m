From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: jic23@kernel.org, dlechner@baylibre.com, nuno.sa@analog.com, 
 andy@kernel.org
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org
Subject: [PATCH] iio: inkern: guard fwnode_xlate with info_exist_lock
Date: Wed, 25 Nov 2026 23:48:27 +0000
Message-Id: <20261125234827.94791-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795650508; l=2248;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=UwI8MEOFQMNXYrZCfHn2V0m8wxZqqR1RYDKf/G0SIio=;
 b=rTYVmb1iDg1w9r+pQu3nCr/1QL3iCZWFQzBPwBrnjrGm/KhD0BTxuqrwN9TuMeW/I+OPjWKoW
 Ex0DWM6YHhmBC2RYJ9mZ047mkZG6667zSfQlo5HmEBy7xs1xZArOQRF
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__fwnode_iio_channel_get() dereferences indio_dev->info->fwnode_xlate
and invokes it without holding info_exist_lock. Concurrent
iio_device_unregister() clears indio_dev->info under info_exist_lock,
allowing a NULL dereference or callback execution during provider
teardown.

Hold iio_dev_opaque->info_exist_lock with scoped_guard(mutex, ...)
matching the rest of inkern.c, return -ENODEV if indio_dev->info is
NULL, and bounds-check the translated index against
indio_dev->num_channels before indexing indio_dev->channels.

Found and drafted with an AI coding assistant.

Fixes: acd8256723f2 ("iio: inkern: Add of_xlate function to struct iio_info")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/iio/inkern.c | 19 ++++++++++++++-----
 1 file changed, 14 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/inkern.c b/drivers/iio/inkern.c
index 1f22275..1a64b71 100644
--- a/drivers/iio/inkern.c
+++ b/drivers/iio/inkern.c
@@ -145,6 +145,7 @@ static int __fwnode_iio_channel_get(struct iio_channel *channel,
 				    struct fwnode_handle *fwnode, int index)
 {
 	struct fwnode_reference_args iiospec;
+	struct iio_dev_opaque *iio_dev_opaque;
 	struct device *idev;
 	struct iio_dev *indio_dev;
 	int err;
@@ -162,15 +163,23 @@ static int __fwnode_iio_channel_get(struct iio_channel *channel,
 	}
 
 	indio_dev = dev_to_iio_dev(idev);
+	iio_dev_opaque = to_iio_dev_opaque(indio_dev);
 	channel->indio_dev = indio_dev;
-	if (indio_dev->info->fwnode_xlate)
-		index = indio_dev->info->fwnode_xlate(indio_dev, &iiospec);
-	else
-		index = __fwnode_iio_simple_xlate(indio_dev, &iiospec);
+	scoped_guard(mutex, &iio_dev_opaque->info_exist_lock) {
+		if (!indio_dev->info)
+			index = -ENODEV;
+		else if (indio_dev->info->fwnode_xlate)
+			index = indio_dev->info->fwnode_xlate(indio_dev, &iiospec);
+		else
+			index = __fwnode_iio_simple_xlate(indio_dev, &iiospec);
+		if (index >= indio_dev->num_channels)
+			index = -EINVAL;
+		if (index >= 0)
+			channel->channel = &indio_dev->channels[index];
+	}
 	fwnode_handle_put(iiospec.fwnode);
 	if (index < 0)
 		goto err_put;
-	channel->channel = &indio_dev->channels[index];
 
 	return 0;
 
-- 
2.54.0 (Apple Git-157)


