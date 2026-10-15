From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 15 Oct 2026 13:49:42 -0300
Subject: [PATCH 02/10] iio: backend: add devm_iio_backend_get_optional()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-ad9910-backend-support-v1-2-3c21648c8e26@analog.com>
References: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
In-Reply-To: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792082993; l=4254;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=jMGRlIFAVCCUz4CCoYv97h4Bqb1DwkRQZ4omjdnHBPA=;
 b=rep/gWP6o7g0TuJDFbq5uZXAbtNeavCTcABecjt66g/dm2woALLaNAba8Ug2NM/XoRo2H/5tz
 jT5VQnTMh+rBpuJryTB+8YUz+Mea9VapIxuo8G5I8dpvie+TTZlLlk7
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Frontend devices might not need a backend driver to rely on. An IIO device
that supports backends can behave differently when they are not available
and that should be acceptable. Such parts may provide basic functionality
solely using the control interface (SPI for instance), being able to have
extended features when a backend is present.

Add devm_iio_backend_get_optional(), which returns NULL when the backend
is not described in firmware, i.e., when the io-backends property is not
present or, for a named lookup, when the name is not listed in the
io-backend-names property. Other errors, such as probe deferral, are
still returned.

To make that possible, a named lookup that does not match any entry of
io-backend-names now fails with -ENOENT, the same error returned when the
io-backends reference is missing. Also, the missing reference is no longer
logged as an error, leaving that to the caller.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-backend.c | 34 +++++++++++++++++++++++++++++++++-
 include/linux/iio/backend.h        |  2 ++
 2 files changed, 35 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/industrialio-backend.c b/drivers/iio/industrialio-backend.c
index fbf5c39d7655..7af41ba50a65 100644
--- a/drivers/iio/industrialio-backend.c
+++ b/drivers/iio/industrialio-backend.c
@@ -1006,9 +1006,14 @@ static struct iio_backend *__devm_iio_backend_fwnode_get_by_index(struct device
 
 	struct fwnode_handle *fwnode_back __free(fwnode_handle) =
 		fwnode_find_reference(fwnode, "io-backends", index);
-	if (IS_ERR(fwnode_back))
+	if (IS_ERR(fwnode_back)) {
+		/* not described in firmware, let the caller decide what to do */
+		if (PTR_ERR(fwnode_back) == -ENOENT)
+			return ERR_CAST(fwnode_back);
+
 		return dev_err_cast_probe(dev, fwnode_back,
 					  "Cannot get Firmware reference\n");
+	}
 
 	guard(mutex)(&iio_back_lock);
 	list_for_each_entry(back, &iio_back_list, entry) {
@@ -1035,6 +1040,8 @@ static struct iio_backend *__devm_iio_backend_fwnode_get(struct device *dev, con
 
 	if (name) {
 		ret = device_property_match_string(dev, "io-backend-names", name);
+		if (ret == -EINVAL || ret == -ENODATA)
+			return ERR_PTR(-ENOENT);
 		if (ret < 0)
 			return ERR_PTR(ret);
 		index = ret;
@@ -1061,6 +1068,31 @@ struct iio_backend *devm_iio_backend_get(struct device *dev, const char *name)
 }
 EXPORT_SYMBOL_NS_GPL(devm_iio_backend_get, "IIO_BACKEND");
 
+/**
+ * devm_iio_backend_get_optional - Optional device managed backend device get
+ * @dev: Consumer device for the backend
+ * @name: Backend name
+ *
+ * Gets the backend associated with @dev. A backend not described in firmware,
+ * i.e., the io-backends property is not present or @name is not listed in
+ * the io-backend-names property, is not treated as an error.
+ *
+ * RETURNS:
+ * A backend pointer, NULL if the backend is not described in firmware,
+ * negative error pointer otherwise.
+ */
+struct iio_backend *devm_iio_backend_get_optional(struct device *dev,
+						  const char *name)
+{
+	struct iio_backend *back = devm_iio_backend_get(dev, name);
+
+	if (IS_ERR(back) && PTR_ERR(back) == -ENOENT)
+		return NULL;
+
+	return back;
+}
+EXPORT_SYMBOL_NS_GPL(devm_iio_backend_get_optional, "IIO_BACKEND");
+
 /**
  * devm_iio_backend_get_by_index - Device managed backend device get by index
  * @dev: Consumer device for the backend
diff --git a/include/linux/iio/backend.h b/include/linux/iio/backend.h
index 9c16b695a602..93d5f2073cc3 100644
--- a/include/linux/iio/backend.h
+++ b/include/linux/iio/backend.h
@@ -267,6 +267,8 @@ int iio_backend_extend_chan_spec(struct iio_backend *back,
 bool iio_backend_has_caps(struct iio_backend *back, u32 caps);
 void *iio_backend_get_priv(const struct iio_backend *conv);
 struct iio_backend *devm_iio_backend_get(struct device *dev, const char *name);
+struct iio_backend *devm_iio_backend_get_optional(struct device *dev,
+						  const char *name);
 struct iio_backend *devm_iio_backend_get_by_index(struct device *dev, unsigned int index);
 struct iio_backend *devm_iio_backend_fwnode_get(struct device *dev,
 						const char *name,

-- 
2.43.0

