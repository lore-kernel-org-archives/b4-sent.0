From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 25 Jul 2025 07:32:55 +0100
Subject: [PATCH] iio: buffer: buffer-cb: drop double initialization of
 demux list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250725-iio-minor-cleanup-v1-1-4e561372142e@analog.com>
X-B4-Tracking: v=1; b=H4sIABYlg2gC/x3MQQqAIBBA0avErBtIS6yuEi3EphooFaUIwrsnL
 d/i/xcSRaYEY/VCpJsTe1cg6grsbtxGyEsxyEaqRkuFzB5Pdj6iPci4K+DQmVborqfVKihdiLT
 y8z+nOecPkuAZ8mMAAAA=
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753425190; l=967;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=WZdMjbzA4w28HJI0E9xLfu9MeSAA6z1IDKHR/cf1+5c=;
 b=gE/XGhhk+L8zJrKCpXfbW+99Q0fn3VQa9EBMCNVE6FmNUMi3kjmb6ltwqsze1pt/tqk2J/KTq
 Vqado82/cNVClS+x7a72OMK4Dn6J/6golhyuQX0diavTTeMA6d8pkDS
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop the call to INIT_LIST_HEAD(&cb_buff->buffer.demux_list). That's
already done in iio_buffer_init(&cb_buff->buffer).

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-cb.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-cb.c b/drivers/iio/buffer/industrialio-buffer-cb.c
index 4befc9f55201e..3e27385069edb 100644
--- a/drivers/iio/buffer/industrialio-buffer-cb.c
+++ b/drivers/iio/buffer/industrialio-buffer-cb.c
@@ -68,7 +68,6 @@ struct iio_cb_buffer *iio_channel_get_all_cb(struct device *dev,
 	cb_buff->private = private;
 	cb_buff->cb = cb;
 	cb_buff->buffer.access = &iio_cb_access;
-	INIT_LIST_HEAD(&cb_buff->buffer.demux_list);
 
 	cb_buff->channels = iio_channel_get_all(dev);
 	if (IS_ERR(cb_buff->channels)) {

---
base-commit: a10185367eccb4d79efdeb09eb59c964ca7659f7
change-id: 20250725-iio-minor-cleanup-94a31748efc5
--

Thanks!
- Nuno Sá

