From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 27 Nov 2026 09:47:44 +0000
Subject: [PATCH v2 1/5] iio: core: emit channel prefixes into a struct
 seq_buf
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-iio-core-attr-review-v2-1-e0aed1e8a81c@analog.com>
References: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
In-Reply-To: <20261127-iio-core-attr-review-v2-0-e0aed1e8a81c@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795772875; l=3352;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=dMRekQ/faBreODE2xVwTa3Gmbpv2kNnDqBlJ6+rvKGA=;
 b=uPgcgI1EKqF3hLPjrSBFZipofI3leTzGnDx6RE9iKl0DN1CeWRhr0UuDC4mOFIFPJa0heSDBi
 gBhRLvdt+KRD9VzpEm0vmEyZp7BQtXDTnBZ954ywOsR/2b3wyu8tlQu
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__iio_chan_prefix_emit() builds the channel prefix of an attribute name
through a struct seq_buf that is local to the function, so a caller that
wants to append to the prefix has to deal with the buffer offset itself.

Move the prefix logic into iio_chan_prefix_seq_buf(), which takes the
struct seq_buf directly and returns the length of the prefix, and keep
__iio_chan_prefix_emit() as a wrapper for its current users. This lets
the IIO core build a full attribute name in a single struct seq_buf.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 46 ++++++++++++++++++++++++++---------------
 1 file changed, 29 insertions(+), 17 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index dabd57a0994e..5267a9c5908c 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -206,28 +206,24 @@ static const char * const iio_chan_info_postfix[] = {
 	[IIO_CHAN_INFO_POWERFACTOR] = "powerfactor",
 };
 
-VISIBLE_IF_KUNIT
-ssize_t __iio_chan_prefix_emit(struct device *dev,
-			       const struct iio_chan_spec *chan,
-			       enum iio_shared_by shared_by,
-			       char *buf, size_t len)
+static ssize_t iio_chan_prefix_seq_buf(struct device *dev,
+				       const struct iio_chan_spec *chan,
+				       enum iio_shared_by shared_by,
+				       struct seq_buf *s)
 {
 	const char *type = iio_chan_type_name_spec[chan->type];
 	const char *dir = iio_direction[chan->output];
-	struct seq_buf s;
-
-	seq_buf_init(&s, buf, len);
 
 	switch (shared_by) {
 	case IIO_SHARED_BY_ALL:
 		break;
 	case IIO_SHARED_BY_DIR:
-		seq_buf_printf(&s, "%s", dir);
+		seq_buf_printf(s, "%s", dir);
 		break;
 	case IIO_SHARED_BY_TYPE:
-		seq_buf_printf(&s, "%s_%s", dir, type);
+		seq_buf_printf(s, "%s_%s", dir, type);
 		if (chan->differential)
-			seq_buf_printf(&s, "-%s", type);
+			seq_buf_printf(s, "-%s", type);
 		break;
 	case IIO_SEPARATE:
 		/* Validate differential channel settings */
@@ -242,23 +238,39 @@ ssize_t __iio_chan_prefix_emit(struct device *dev,
 			}
 		}
 
-		seq_buf_printf(&s, "%s_%s", dir, type);
+		seq_buf_printf(s, "%s_%s", dir, type);
 
 		if (chan->indexed)
-			seq_buf_printf(&s, "%d", chan->channel);
+			seq_buf_printf(s, "%d", chan->channel);
 
 		if (chan->differential)
-			seq_buf_printf(&s, "-%s%d", type, chan->channel2);
+			seq_buf_printf(s, "-%s%d", type, chan->channel2);
 
 		if (chan->modified)
-			seq_buf_printf(&s, "_%s", iio_modifier_names[chan->channel2]);
+			seq_buf_printf(s, "_%s", iio_modifier_names[chan->channel2]);
 
 		if (chan->extend_name)
-			seq_buf_printf(&s, "_%s", chan->extend_name);
+			seq_buf_printf(s, "_%s", chan->extend_name);
 		break;
 	}
 
-	return seq_buf_has_overflowed(&s) ? -EOVERFLOW : s.len;
+	if (seq_buf_has_overflowed(s))
+		return -EOVERFLOW;
+
+	return seq_buf_used(s);
+}
+
+VISIBLE_IF_KUNIT
+ssize_t __iio_chan_prefix_emit(struct device *dev,
+			       const struct iio_chan_spec *chan,
+			       enum iio_shared_by shared_by,
+			       char *buf, size_t len)
+{
+	struct seq_buf s;
+
+	seq_buf_init(&s, buf, len);
+
+	return iio_chan_prefix_seq_buf(dev, chan, shared_by, &s);
 }
 EXPORT_SYMBOL_IF_KUNIT(__iio_chan_prefix_emit);
 

-- 
2.43.0

