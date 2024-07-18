From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:50 +0200
Subject: [PATCH 04/22] iio: dummy: iio_simple_dummy_buffer: use
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-4-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=993;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=/UO8BlopWO9kmVPYMQiw2xtRzt9uK+mubBziqer1//A=;
 b=oXw9qCYMnxtytq6HBGd4NwY68O+4p10py3M6nZ+33FC5VQJ7Qf/FVIO67fEdsWoqP7BP3WmA7
 OEu7Uv6GvZEDkUcbXFULAQNYxW6CwAiev5zNjWbFAQGYj8lJRLGBXRZ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/dummy/iio_simple_dummy_buffer.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/dummy/iio_simple_dummy_buffer.c b/drivers/iio/dummy/iio_simple_dummy_buffer.c
index 9b2f99449a829..4ca3f1aaff999 100644
--- a/drivers/iio/dummy/iio_simple_dummy_buffer.c
+++ b/drivers/iio/dummy/iio_simple_dummy_buffer.c
@@ -68,7 +68,7 @@ static irqreturn_t iio_simple_dummy_trigger_h(int irq, void *p)
 	 * Here let's pretend we have random access. And the values are in the
 	 * constant table fakedata.
 	 */
-	for_each_set_bit(j, indio_dev->active_scan_mask, indio_dev->masklength)
+	iio_for_each_active_channel(indio_dev, j)
 		data[i++] = fakedata[j];
 
 	iio_push_to_buffers_with_timestamp(indio_dev, data,

-- 
2.45.2

