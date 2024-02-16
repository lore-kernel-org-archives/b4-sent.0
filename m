From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 16 Feb 2024 15:10:55 +0100
Subject: [PATCH RFC 6/8] iio: backend: add new backend ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-iio-backend-axi-dds-v1-6-22aed9fb07a1@analog.com>
References: <20240216-iio-backend-axi-dds-v1-0-22aed9fb07a1@analog.com>
In-Reply-To: <20240216-iio-backend-axi-dds-v1-0-22aed9fb07a1@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708092664; l=8015;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=rN0QCjqlMVi6zhSqFla2kqXViqpt4/ebJYdlaVhTU4w=;
 b=tWjrufsIIy7RSRrg6PW8H8zFeFPTk1jCjL2uOcJrCQVney0BQhF3jSZch1Rk+J6TjZXXxvEUa
 JR74dN65SzwAYXrXmQeQz6bdXeBGRbjnz/Q/1/cH1LGxMOKyRj06dJJ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The following new ops are being added:
- iio_backend_data_source_set()
- iio_backend_read_phase()
- iio_backend_write_phase()
- iio_backend_read_scale()
- iio_backend_write_scale()
- iio_backend_read_frequency()
- iio_backend_write_frequency()

The new iio_backend_data_source_set() allows to select the data source
on a backend. It can for example be used when enabling/disabling a
buffer to mux between different data sources.

The rest of the APIs mostly resemble (apart from read/write frequency
which have a couple of new arguments) the typical read/write raw
functions (but fine grained for a specific attribute).

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-backend.c | 65 ++++++++++++++++++++++++++++++++++++++
 include/linux/iio/backend.h        | 53 ++++++++++++++++++++++++++++++-
 2 files changed, 117 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/industrialio-backend.c b/drivers/iio/industrialio-backend.c
index 2fea2bbbe47f..bf26c41872ca 100644
--- a/drivers/iio/industrialio-backend.c
+++ b/drivers/iio/industrialio-backend.c
@@ -43,6 +43,7 @@
 #include <linux/types.h>
 
 #include <linux/iio/backend.h>
+#include <linux/iio/iio.h>
 
 struct iio_backend {
 	struct list_head entry;
@@ -186,6 +187,16 @@ int iio_backend_data_format_set(struct iio_backend *back, unsigned int chan,
 }
 EXPORT_SYMBOL_NS_GPL(iio_backend_data_format_set, IIO_BACKEND);
 
+int iio_backend_data_source_set(struct iio_backend *back, unsigned int chan,
+				enum iio_backend_data_source data)
+{
+	if (data >= IIO_BACKEND_DATA_SOURCE_MAX)
+		return -EINVAL;
+
+	return iio_backend_op_call(back, data_source_set, chan, data);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_data_source_set, IIO_BACKEND);
+
 static void iio_backend_free_buffer(void *arg)
 {
 	struct iio_backend_buffer_pair *pair = arg;
@@ -231,6 +242,60 @@ int devm_iio_backend_request_buffer(struct device *dev,
 }
 EXPORT_SYMBOL_NS_GPL(devm_iio_backend_request_buffer, IIO_BACKEND);
 
+int iio_backend_read_phase(struct iio_backend *back,
+			   const struct iio_chan_spec *chan, int *val,
+			   int *val2, unsigned int tone_idx)
+{
+	return iio_backend_op_call(back, read_phase, chan, val, val2, tone_idx);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_read_phase, IIO_BACKEND);
+
+int iio_backend_write_phase(struct iio_backend *back,
+			    const struct iio_chan_spec *chan, int val,
+			    int val2, unsigned int tone_idx)
+{
+	return iio_backend_op_call(back, write_phase, chan, val, val2,
+				   tone_idx);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_write_phase, IIO_BACKEND);
+
+int iio_backend_read_scale(struct iio_backend *back,
+			   const struct iio_chan_spec *chan, int *val,
+			   int *val2, unsigned int tone_idx)
+{
+	return iio_backend_op_call(back, read_scale, chan, val, val2, tone_idx);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_read_scale, IIO_BACKEND);
+
+int iio_backend_write_scale(struct iio_backend *back,
+			    const struct iio_chan_spec *chan, int val,
+			    int val2, unsigned int tone_idx)
+{
+	return iio_backend_op_call(back, write_scale, chan, val, val2,
+				   tone_idx);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_write_scale, IIO_BACKEND);
+
+int iio_backend_read_frequency(struct iio_backend *back,
+			       const struct iio_chan_spec *chan, int *val,
+			       int *val2, unsigned int tone_idx,
+			       unsigned long long sample_freq)
+{
+	return iio_backend_op_call(back, read_frequency, chan, val, val2,
+				   tone_idx, sample_freq);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_read_frequency, IIO_BACKEND);
+
+int iio_backend_write_frequency(struct iio_backend *back,
+				const struct iio_chan_spec *chan, int val,
+				int val2, unsigned int tone_idx,
+				unsigned long long sample_freq)
+{
+	return iio_backend_op_call(back, write_frequency, chan, val, val2,
+				   tone_idx, sample_freq);
+}
+EXPORT_SYMBOL_NS_GPL(iio_backend_write_frequency, IIO_BACKEND);
+
 static void iio_backend_release(void *arg)
 {
 	struct iio_backend *back = arg;
diff --git a/include/linux/iio/backend.h b/include/linux/iio/backend.h
index a6d79381866e..c5bcbe89cb64 100644
--- a/include/linux/iio/backend.h
+++ b/include/linux/iio/backend.h
@@ -4,6 +4,7 @@
 
 #include <linux/types.h>
 
+struct iio_chan_spec;
 struct fwnode_handle;
 struct iio_backend;
 struct device;
@@ -15,6 +16,12 @@ enum iio_backend_data_type {
 	IIO_BACKEND_DATA_TYPE_MAX
 };
 
+enum iio_backend_data_source {
+	IIO_BACKEND_INTERNAL_CW,
+	IIO_BACKEND_EXTERNAL,
+	IIO_BACKEND_DATA_SOURCE_MAX
+};
+
 /**
  * struct iio_backend_data_fmt - Backend data format
  * @type:		Data type.
@@ -45,10 +52,33 @@ struct iio_backend_ops {
 	int (*chan_disable)(struct iio_backend *back, unsigned int chan);
 	int (*data_format_set)(struct iio_backend *back, unsigned int chan,
 			       const struct iio_backend_data_fmt *data);
+	int (*data_source_set)(struct iio_backend *back, unsigned int chan,
+			       enum iio_backend_data_source data);
+
 	struct iio_buffer *(*request_buffer)(struct iio_backend *back,
 					     struct iio_dev *indio_dev);
 	void (*free_buffer)(struct iio_backend *back,
 			    struct iio_buffer *buffer);
+	int (*read_phase)(struct iio_backend *back,
+			  const struct iio_chan_spec *chan, int *val, int *val2,
+			  unsigned int tone_idx);
+	int (*write_phase)(struct iio_backend *back,
+			   const struct iio_chan_spec *chan, int val, int val2,
+			   unsigned int tone_idx);
+	int (*read_scale)(struct iio_backend *back,
+			  const struct iio_chan_spec *chan, int *val, int *val2,
+			  unsigned int tone_idx);
+	int (*write_scale)(struct iio_backend *back,
+			   const struct iio_chan_spec *chan, int val, int val2,
+			   unsigned int tone_idx);
+	int (*read_frequency)(struct iio_backend *back,
+			      const struct iio_chan_spec *chan, int *val,
+			      int *val2, unsigned int tone_idx,
+			      unsigned long long sample_freq);
+	int (*write_frequency)(struct iio_backend *back,
+			       const struct iio_chan_spec *chan, int val,
+			       int val2, unsigned int tone_idx,
+			       unsigned long long sample_freq);
 };
 
 int iio_backend_chan_enable(struct iio_backend *back, unsigned int chan);
@@ -56,10 +86,31 @@ int iio_backend_chan_disable(struct iio_backend *back, unsigned int chan);
 int devm_iio_backend_enable(struct device *dev, struct iio_backend *back);
 int iio_backend_data_format_set(struct iio_backend *back, unsigned int chan,
 				const struct iio_backend_data_fmt *data);
+int iio_backend_data_source_set(struct iio_backend *back, unsigned int chan,
+				enum iio_backend_data_source data);
 int devm_iio_backend_request_buffer(struct device *dev,
 				    struct iio_backend *back,
 				    struct iio_dev *indio_dev);
-
+int iio_backend_read_phase(struct iio_backend *back,
+			   const struct iio_chan_spec *chan, int *val,
+			   int *val2, unsigned int tone_idx);
+int iio_backend_write_phase(struct iio_backend *back,
+			    const struct iio_chan_spec *chan, int val,
+			    int val2, unsigned int tone_idx);
+int iio_backend_read_scale(struct iio_backend *back,
+			   const struct iio_chan_spec *chan, int *val,
+			   int *val2, unsigned int tone_idx);
+int iio_backend_write_scale(struct iio_backend *back,
+			    const struct iio_chan_spec *chan, int val,
+			    int val2, unsigned int tone_idx);
+int iio_backend_read_frequency(struct iio_backend *back,
+			       const struct iio_chan_spec *chan, int *val,
+			       int *val2, unsigned int tone_idx,
+			       unsigned long long sample_freq);
+int iio_backend_write_frequency(struct iio_backend *back,
+				const struct iio_chan_spec *chan, int val,
+				int val2, unsigned int tone_idx,
+				unsigned long long sample_freq);
 void *iio_backend_get_priv(const struct iio_backend *conv);
 struct iio_backend *devm_iio_backend_get(struct device *dev, const char *name);
 struct iio_backend *

-- 
2.43.0

