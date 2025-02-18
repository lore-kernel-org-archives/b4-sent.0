From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 18 Feb 2025 10:34:57 +0000
Subject: [PATCH] iio: adc: adi-axi-adc: replace of.h with mod_devicetable.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250218-dev-axi-adc-fix-headers-v1-1-5ddc79221d8c@analog.com>
X-B4-Tracking: v=1; b=H4sIAFFitGcC/x2MwQqAIBAFf0X23EIKRfQr0UHbV+2lQiEE8d+Tj
 sMwUyghKhLNplDEq0nvq4HtDG2nvw6wSmNyvRt6ZycWvOyzspeNd818wgti4uBErASxASO1+ol
 o+j8va60fpJ9PmmkAAAA=
X-Change-ID: 20250218-dev-axi-adc-fix-headers-b2dd1dbd1be6
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739874907; l=903;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=G3VoJon8QjFBAHChuMI22zdjNcH5B5joBOnnLh6sUCU=;
 b=iFj28nRQjkaqZ/g9GRd+6bAwkbm1olOc/3LY6rPl77rdiY77uZ75X9KFDawGK4InHg7KsQdGZ
 gRyU/V7oL8kB1z3u3mvxRg2C6xGwI933wK6cc/Ua4UcpSGUIKf1eLlq
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Don't use of.h in order to include mod_devicetable.h. Use it directly as
there no direct dependency on OF.h

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 61ab7dce43be66868f09c41df18d09259db0cee3..068a1f61c6329967e39e8fcde70f0c903aaa6393 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -14,7 +14,7 @@
 #include <linux/delay.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
-#include <linux/of.h>
+#include <linux/mod_devicetable.h>
 #include <linux/platform_device.h>
 #include <linux/property.h>
 #include <linux/regmap.h>

---
base-commit: c0f115a8d97599623294c8e9ec28530e19c1e85b
change-id: 20250218-dev-axi-adc-fix-headers-b2dd1dbd1be6
--

Thanks!
- Nuno Sá

