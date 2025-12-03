From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 03 Dec 2025 15:11:36 +0000
Subject: [PATCH 1/6] iio: buffer-dma: use lockdep instead of WARN()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251203-iio-dmabuf-improvs-v1-1-0e4907ce7322@analog.com>
References: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
In-Reply-To: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764774697; l=1113;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=q3xzONCOKbjzU83uO5v2RZKwpfbxm04ZQK8NV2XP1fs=;
 b=hXwu7OyGp+n8oGduTudhJGR7uB4NweKGe7u7oJrOLIXyEXRCaLyTHfyPzKj1W4JFbbJdRH1xd
 7F555Q5kEoKB6ElEfBq4AtEmnB/UZpTds4oww6/YVDTJGGkxWqqYDJ8
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As documented, WARN() should be used with care given that it can panic
running kernels (depending on command line options). So, instead of
using it to make sure a lock is held, use the annotations we already
have in the kernel for the very same reason.

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

