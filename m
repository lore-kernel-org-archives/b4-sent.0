From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 17:22:01 +0100
Subject: [PATCH v4 1/6] printk: add new dev_errp_probe() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-ltc2983-misc-improv-v4-1-0cc428c07cd5@analog.com>
References: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
In-Reply-To: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jyoti Bhayana <jbhayana@google.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711642925; l=860;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=vXOLsOw6+C77AIWiu90FWpD8kygNarvvpJ/k/VruOcs=;
 b=64nglCnPkvcJectWPXgIGHdCtTNeyHylZlWDbeBrURS5fXiWuIaps6bEP0qGZsmALZb8I1CI0
 vZgLbagCniUC49mYmTeUqCiM6uaPJg7sZbVwEMLKpfJnk2m5TgGd2VF
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is similar to dev_err_probe() but for cases where an ERR_PTR() is
to be returned simplifying patterns like:

	dev_err_probe(dev, ret, ...);
	return ERR_PTR(ret)

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 include/linux/dev_printk.h | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/include/linux/dev_printk.h b/include/linux/dev_printk.h
index 6bfe70decc9f..64484d092a77 100644
--- a/include/linux/dev_printk.h
+++ b/include/linux/dev_printk.h
@@ -276,4 +276,9 @@ do {									\
 
 __printf(3, 4) int dev_err_probe(const struct device *dev, int err, const char *fmt, ...);
 
+/* Simple helper for dev_err_probe() when ERR_PTR() is to be returned. */
+#define dev_errp_probe(dev, ___err, fmt, ...)	({		\
+	ERR_PTR(dev_err_probe(dev, ___err, fmt, ##__VA_ARGS__));	\
+})
+
 #endif /* _DEVICE_PRINTK_H_ */

-- 
2.44.0

