From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:52 +0200
Subject: [PATCH 06/22] iio: health: max30102: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-6-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=863;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=5H69UJpKUwhjYrie33oP+IHHh9ZtV6RkXSkhlBGw/AI=;
 b=LJwYzuHnG/NrWF7XM+KhWCZVueUkEEQ3LNJ2lO7iP/9SoPXyXwIZtaGzQtgRrFuLn/MtuBaW3
 o8AR5sFGOstCjFKOxJtlFNQz096VzVTFA8XKJXSday3GOklaQUqKW58
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/health/max30102.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/health/max30102.c b/drivers/iio/health/max30102.c
index 07a343e35a81..1d074eb6a8c5 100644
--- a/drivers/iio/health/max30102.c
+++ b/drivers/iio/health/max30102.c
@@ -293,7 +293,7 @@ static irqreturn_t max30102_interrupt_handler(int irq, void *private)
 	struct iio_dev *indio_dev = private;
 	struct max30102_data *data = iio_priv(indio_dev);
 	unsigned int measurements = bitmap_weight(indio_dev->active_scan_mask,
-						  indio_dev->masklength);
+						  iio_get_masklength(indio_dev));
 	int ret, cnt = 0;
 
 	mutex_lock(&data->lock);

-- 
2.45.2

