From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Nov 2026 16:39:55 +0000
Subject: [PATCH v4 03/12] iio: backend: use the consumer fwnode for named
 lookups
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-ad9910-backend-support-v4-3-fcf1ad364ed5@analog.com>
References: <20261116-ad9910-backend-support-v4-0-fcf1ad364ed5@analog.com>
In-Reply-To: <20261116-ad9910-backend-support-v4-0-fcf1ad364ed5@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794847197; l=1465;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Aqd7cXKBKNmzoZvZz6wBTgwNO0tV9BfSYFDnK0IgmaA=;
 b=zQO3o3/r28xNjDjGsijCE1stfX+0fyvRhA4KM0FaJOxu0c5VtuhGhr+72tRNA3JVXtMfzxknS
 BJyNc2KPSg7BrMkuYzkQPWBKlF0lG1MAYBi6+6NuEO1+WL+NbVX6DP+
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__devm_iio_backend_fwnode_get() receives the consumer fwnode, which is
used to resolve the io-backends reference. However, for a named lookup,
the index is obtained from the io-backend-names property of the device
instead. When devm_iio_backend_fwnode_get() is called with a fwnode other
than the device one, such as a child node, the name is then matched
against the wrong node, either failing or returning the index of a
different backend.

Look up io-backend-names in the given fwnode, so that both properties
are read from the same node.

The only current user of devm_iio_backend_fwnode_get() does not provide
a name, so it is not affected.

Fixes: c464cc610f51 ("iio: add child nodes support in iio backend framework")
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-backend.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/industrialio-backend.c b/drivers/iio/industrialio-backend.c
index fbf5c39d7655..9a1072b39815 100644
--- a/drivers/iio/industrialio-backend.c
+++ b/drivers/iio/industrialio-backend.c
@@ -1034,7 +1034,7 @@ static struct iio_backend *__devm_iio_backend_fwnode_get(struct device *dev, con
 	int ret;
 
 	if (name) {
-		ret = device_property_match_string(dev, "io-backend-names", name);
+		ret = fwnode_property_match_string(fwnode, "io-backend-names", name);
 		if (ret < 0)
 			return ERR_PTR(ret);
 		index = ret;

-- 
2.43.0

