From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 05 Jul 2024 17:12:42 +0200
Subject: [PATCH v2 4/4] spi: xcomm: fix coding style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-dev-spi-xcomm-gpiochip-v2-4-b10842fc9636@analog.com>
References: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
In-Reply-To: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
To: linux-spi@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720192365; l=3472;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ZgTAmJ7IiP/e7QA90qtxl89+pg3ESD6JiaVtHgJhCxY=;
 b=mmZyYgI6j028rWMPshdA/87V+jdmdoK9pGog9cUMJ7+yuiqzeYPF+aYCnH5vUqMFXU18G+fH+
 s19DqRRY0WXCByCDIqcx/BLBGRy01ORQGEt0MX89FwThPTXolUeQKsJ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just cosmetics. No functional change intended.

While at it, removed a couple of redundant else if() statements.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/spi/spi-xcomm.c | 28 ++++++++++++++--------------
 1 file changed, 14 insertions(+), 14 deletions(-)

diff --git a/drivers/spi/spi-xcomm.c b/drivers/spi/spi-xcomm.c
index 1cd7d2b9e11c9..846f00e23b717 100644
--- a/drivers/spi/spi-xcomm.c
+++ b/drivers/spi/spi-xcomm.c
@@ -36,12 +36,12 @@ struct spi_xcomm {
 
 	struct gpio_chip gc;
 
-	uint16_t settings;
-	uint16_t chipselect;
+	u16 settings;
+	u16 chipselect;
 
 	unsigned int current_speed;
 
-	uint8_t buf[63];
+	u8 buf[63];
 };
 
 static void spi_xcomm_gpio_set_value(struct gpio_chip *chip,
@@ -82,8 +82,8 @@ static int spi_xcomm_gpio_add(struct spi_xcomm *spi_xcomm)
 
 static int spi_xcomm_sync_config(struct spi_xcomm *spi_xcomm, unsigned int len)
 {
-	uint16_t settings;
-	uint8_t *buf = spi_xcomm->buf;
+	u16 settings;
+	u8 *buf = spi_xcomm->buf;
 
 	settings = spi_xcomm->settings;
 	settings |= len << SPI_XCOMM_SETTINGS_LEN_OFFSET;
@@ -96,10 +96,10 @@ static int spi_xcomm_sync_config(struct spi_xcomm *spi_xcomm, unsigned int len)
 }
 
 static void spi_xcomm_chipselect(struct spi_xcomm *spi_xcomm,
-	struct spi_device *spi, int is_active)
+				 struct spi_device *spi, int is_active)
 {
 	unsigned long cs = spi_get_chipselect(spi, 0);
-	uint16_t chipselect = spi_xcomm->chipselect;
+	u16 chipselect = spi_xcomm->chipselect;
 
 	if (is_active)
 		chipselect |= BIT(cs);
@@ -110,7 +110,8 @@ static void spi_xcomm_chipselect(struct spi_xcomm *spi_xcomm,
 }
 
 static int spi_xcomm_setup_transfer(struct spi_xcomm *spi_xcomm,
-	struct spi_device *spi, struct spi_transfer *t, unsigned int *settings)
+				    struct spi_device *spi, struct spi_transfer *t,
+				    unsigned int *settings)
 {
 	if (t->len > 62)
 		return -EINVAL;
@@ -148,7 +149,7 @@ static int spi_xcomm_setup_transfer(struct spi_xcomm *spi_xcomm,
 }
 
 static int spi_xcomm_txrx_bufs(struct spi_xcomm *spi_xcomm,
-	struct spi_device *spi, struct spi_transfer *t)
+			       struct spi_device *spi, struct spi_transfer *t)
 {
 	int ret;
 
@@ -159,13 +160,13 @@ static int spi_xcomm_txrx_bufs(struct spi_xcomm *spi_xcomm,
 		ret = i2c_master_send(spi_xcomm->i2c, spi_xcomm->buf, t->len + 1);
 		if (ret < 0)
 			return ret;
-		else if (ret != t->len + 1)
+		if (ret != t->len + 1)
 			return -EIO;
 	} else if (t->rx_buf) {
 		ret = i2c_master_recv(spi_xcomm->i2c, t->rx_buf, t->len);
 		if (ret < 0)
 			return ret;
-		else if (ret != t->len)
+		if (ret != t->len)
 			return -EIO;
 	}
 
@@ -173,12 +174,12 @@ static int spi_xcomm_txrx_bufs(struct spi_xcomm *spi_xcomm,
 }
 
 static int spi_xcomm_transfer_one(struct spi_controller *host,
-	struct spi_message *msg)
+				  struct spi_message *msg)
 {
 	struct spi_xcomm *spi_xcomm = spi_controller_get_devdata(host);
 	unsigned int settings = spi_xcomm->settings;
 	struct spi_device *spi = msg->spi;
-	unsigned cs_change = 0;
+	unsigned int cs_change = 0;
 	struct spi_transfer *t;
 	bool is_first = true;
 	int status = 0;
@@ -187,7 +188,6 @@ static int spi_xcomm_transfer_one(struct spi_controller *host,
 	spi_xcomm_chipselect(spi_xcomm, spi, true);
 
 	list_for_each_entry(t, &msg->transfers, transfer_list) {
-
 		if (!t->tx_buf && !t->rx_buf && t->len) {
 			status = -EINVAL;
 			break;

-- 
2.45.2

