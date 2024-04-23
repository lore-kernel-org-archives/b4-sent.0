From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 23 Apr 2024 17:20:30 +0200
Subject: [PATCH v2 1/4] dev_printk: add new dev_err_probe() helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240423-dev-add_dev_errp_probe-v2-1-12f43c5d8b0d@analog.com>
References: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
In-Reply-To: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
To: Petr Mladek <pmladek@suse.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Chris Down <chris@chrisdown.name>, John Ogness <john.ogness@linutronix.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Andi Shyti <andi.shyti@kernel.org>, Jyoti Bhayana <jbhayana@google.com>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713885641; l=1170;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=9vRT1yB7cKMgARCNN9R6YoimX7EiL0EJICliqmirgVI=;
 b=/OQCs5rmT3dEQ4zj8HcAF6Mlps+bwWIA1WQPIkd72RdXPAjuUXauUJKqTqgJjsdsztQe/iaVU
 QYcWYv80Ea1BvQ0hoiG+TYe08uVVpiyrbj5RnudcUx5EiejSrl/viaE
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is similar to dev_err_probe() but for cases where an ERR_PTR() or
ERR_CAST() is to be returned simplifying patterns like:

	dev_err_probe(dev, ret, ...);
	return ERR_PTR(ret)
or
	dev_err_probe(dev, PTR_ERR(ptr), ...);
	return ERR_CAST(ptr)

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 include/linux/dev_printk.h | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/include/linux/dev_printk.h b/include/linux/dev_printk.h
index ae80a303c216..b9623ec22350 100644
--- a/include/linux/dev_printk.h
+++ b/include/linux/dev_printk.h
@@ -277,4 +277,13 @@ do {									\
 
 __printf(3, 4) int dev_err_probe(const struct device *dev, int err, const char *fmt, ...);
 
+/* Simple helper for dev_err_probe() when ERR_PTR() is to be returned. */
+#define dev_err_ptr_probe(dev, ___err, fmt, ...)	({		\
+	ERR_PTR(dev_err_probe(dev, ___err, fmt, ##__VA_ARGS__));	\
+})
+
+/* Simple helper for dev_err_probe() when ERR_CAST() is to be returned. */
+#define dev_err_cast_probe(dev, ___err_ptr, fmt, ...)	({			\
+	ERR_PTR(dev_err_probe(dev, PTR_ERR(___err_ptr), fmt, ##__VA_ARGS__));	\
+})
 #endif /* _DEVICE_PRINTK_H_ */

-- 
2.44.0

