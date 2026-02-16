From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 16 Feb 2026 13:24:27 +0000
Subject: [PATCH] iio: buffer: Fix wait_queue not being removed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260216-iio-buffer-write-fix-v1-1-bc08b239f37a@analog.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23IJaSPQr0UFzrb1UrL1A+vek4
 wzMZEgkTAn6KoPQxYm3tYCuK5gWt86EHAqDUcYqoy0yb+jPGEnwFj4IIz/Y6BBi541rnYKS7kJ
 F/9thfN8PqEMt72YAAAA=
X-Change-ID: 20260216-iio-buffer-write-fix-31ddf8b2a4a0
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771248279; l=1108;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wgGaI/gfKqTtshRUq5bR1f6wLAM/nnkZhqCz5oA7qag=;
 b=bG9bTAk4c9iO1DsO79uD+3MlBL/AGa6EaxSdcj0pNaGl0ji7vPpH33k65sfLmZSsL8LpubgNi
 /FEcDHJ5MVXCW4KluMqO4/0loz/G5FJ1b/p1CsNF+vmuXpcx3MObGxV
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the edge case where the IIO device is unregistered while we're
buffering, we were directly returning an error without removing the wait
queue. Instead, set 'ret' and break out of the loop.

Fixes: 9eeee3b0bf19 ("iio: Add output buffer support")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/industrialio-buffer.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index c6259213e150..a09c0d263d7f 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -228,8 +228,10 @@ static ssize_t iio_buffer_write(struct file *filp, const char __user *buf,
 	written = 0;
 	add_wait_queue(&rb->pollq, &wait);
 	do {
-		if (!indio_dev->info)
-			return -ENODEV;
+		if (!indio_dev->info) {
+			ret = -ENODEV;
+			break;
+		}
 
 		if (!iio_buffer_space_available(rb)) {
 			if (signal_pending(current)) {

---
base-commit: f52690c50893ef1504990199c8a2dfbb869f38c6
change-id: 20260216-iio-buffer-write-fix-31ddf8b2a4a0
--

Thanks!
- Nuno Sá

