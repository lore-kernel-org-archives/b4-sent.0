From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 06 Aug 2024 15:35:06 +0200
Subject: [PATCH 1/2] iio: dac: adi-axi-dac: support debugfs
 direct_reg_access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240806-dev-backend-dac-direct-reg-access-v1-1-b84a6e8ee8a0@analog.com>
References: <20240806-dev-backend-dac-direct-reg-access-v1-0-b84a6e8ee8a0@analog.com>
In-Reply-To: <20240806-dev-backend-dac-direct-reg-access-v1-0-b84a6e8ee8a0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722951306; l=1361;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=70Psr3VQuqq94rjCoV8WjU8cuWr16U1+KQK+zWEHn9Q=;
 b=ie12noL1qXL6arhMwxrBoobBneNtNwBnKN+DjS9lTltlbrETvPkfDxfdlhTIRMH17epJ+PF5E
 MhQ57UpZhvaD+z9UYp/a36QAzezqyMBTLZ5EFKOwxWWXKgJv5t+ERi4
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make it possible to read/write registers on the backend using the
debugfs interface for it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/dac/adi-axi-dac.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/iio/dac/adi-axi-dac.c b/drivers/iio/dac/adi-axi-dac.c
index 9655705b158b..0cb00f3bec04 100644
--- a/drivers/iio/dac/adi-axi-dac.c
+++ b/drivers/iio/dac/adi-axi-dac.c
@@ -507,6 +507,17 @@ static int axi_dac_set_sample_rate(struct iio_backend *back, unsigned int chan,
 	return 0;
 }
 
+static int axi_dac_reg_access(struct iio_backend *back, unsigned int reg,
+			      unsigned int writeval, unsigned int *readval)
+{
+	struct axi_dac_state *st = iio_backend_get_priv(back);
+
+	if (readval)
+		return regmap_read(st->regmap, reg, readval);
+
+	return regmap_write(st->regmap, reg, writeval);
+}
+
 static const struct iio_backend_ops axi_dac_generic_ops = {
 	.enable = axi_dac_enable,
 	.disable = axi_dac_disable,
@@ -517,6 +528,7 @@ static const struct iio_backend_ops axi_dac_generic_ops = {
 	.ext_info_get = axi_dac_ext_info_get,
 	.data_source_set = axi_dac_data_source_set,
 	.set_sample_rate = axi_dac_set_sample_rate,
+	.debugfs_reg_access = iio_backend_debugfs_ptr(axi_dac_reg_access),
 };
 
 static const struct iio_backend_info axi_dac_generic = {

-- 
2.45.2

