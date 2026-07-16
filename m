From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 16 Jul 2026 13:14:20 +0100
Subject: [PATCH v8 4/8] iio: dac: ad5686: introduce sync operation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-ad5686-new-features-v8-4-ebb0051af5e5@analog.com>
References: <20260716-ad5686-new-features-v8-0-ebb0051af5e5@analog.com>
In-Reply-To: <20260716-ad5686-new-features-v8-0-ebb0051af5e5@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784204073; l=1488;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=r/qY1H+vZyhzoYkk4EjodZz7IAM2Ur2Y6sQJGGqKUy4=;
 b=/SXlnYJ+Wj1KzVrlmx2fi2Qle2YLYnovakj0Gi5/COyKdBG5PK9gHEui/qEUw43eIQ9RmGy2e
 6trwUv6R6GCB4RqQb3nod30lmxrfSFKuM7OKULhI3fB4TTWbP756IJ0
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add sync() to operation to ad5686_bus_ops, which can be used to flush
multiple pending data transfers at once. This is going to be used when
implementing triggered buffer support.

Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.h | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ad5686.h b/drivers/iio/dac/ad5686.h
index 32cb3931413c..ae9aeda2d201 100644
--- a/drivers/iio/dac/ad5686.h
+++ b/drivers/iio/dac/ad5686.h
@@ -70,10 +70,12 @@ struct ad5686_state;
  * struct ad5686_bus_ops - bus specific read/write operations
  * @read: read a register value at the given address
  * @write: write a command, address and value to the device
+ * @sync: ensure the completion of the write operation (optional)
  */
 struct ad5686_bus_ops {
 	int (*read)(struct ad5686_state *st, u8 addr);
 	int (*write)(struct ad5686_state *st, u8 cmd, u8 addr, u16 val);
+	int (*sync)(struct ad5686_state *st);
 };
 
 /**
@@ -162,7 +164,13 @@ int ad5686_probe(struct device *dev,
 
 static inline int ad5686_write(struct ad5686_state *st, u8 cmd, u8 addr, u16 val)
 {
-	return st->ops->write(st, cmd, addr, val);
+	int ret;
+
+	ret = st->ops->write(st, cmd, addr, val);
+	if (ret)
+		return ret;
+
+	return st->ops->sync ? st->ops->sync(st) : 0;
 }
 
 static inline int ad5686_read(struct ad5686_state *st, u8 addr)

-- 
2.43.0

