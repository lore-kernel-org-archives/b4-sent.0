From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 19 Dec 2025 15:28:12 +0000
Subject: [PATCH v2 1/6] iio: buffer-dma: Use lockdep for locking
 annotations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251219-iio-dmabuf-improvs-v2-1-caa76de6e873@analog.com>
References: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
In-Reply-To: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766158092; l=1011;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=vAf7WOSJFQhX0O/kDa00FjN6tPjAcLO8ZihWozrJFJ0=;
 b=LjS9zIiGvfYHLsfj61UIgz3Lz7/btI6EQFYT65zTpp2bMvMhBLc95x5NjqfJb2/xfBz+1+Lfx
 4hk/92MgE7hDawt0r9VSe5K+YLlmaQWtZ1XYCKr3Iso3PmonEoqd0/H
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Don't use mutex_is_locked() + WARN_ON() for checking if a specif lock is
taken. Instead use the existing annotations which means
lockdep_assert_held().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dma.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dma.c b/drivers/iio/buffer/industrialio-buffer-dma.c
index ee294a775e8a..617b2d550c2f 100644
--- a/drivers/iio/buffer/industrialio-buffer-dma.c
+++ b/drivers/iio/buffer/industrialio-buffer-dma.c
@@ -6,6 +6,7 @@
 
 #include <linux/atomic.h>
 #include <linux/cleanup.h>
+#include <linux/lockdep.h>
 #include <linux/slab.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
@@ -764,7 +765,7 @@ int iio_dma_buffer_enqueue_dmabuf(struct iio_buffer *buffer,
 	bool cookie;
 	int ret;
 
-	WARN_ON(!mutex_is_locked(&queue->lock));
+	lockdep_assert_held(&queue->lock);
 
 	cookie = dma_fence_begin_signalling();
 

-- 
2.52.0

