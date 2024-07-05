From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 05 Jul 2024 17:12:40 +0200
Subject: [PATCH v2 2/4] spi: xcomm: make use of devm_spi_alloc_host()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-dev-spi-xcomm-gpiochip-v2-2-b10842fc9636@analog.com>
References: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
In-Reply-To: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
To: linux-spi@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720192365; l=939;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6RJlZH90JdCncjV5ZiRfVjQGYop1z1hLo21odk1aD/A=;
 b=osI/6myKylZYPHyEDCSsLzHduRcTVpyNgmM7465zYO3+Y133WVjNY+80HwVBPeg0SS1mjrklF
 HlvMmRz5AwgAVgF7AJbC5wDRn/E58tto5qrxxHzvAHSvsSIXAKnlTF+
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use devm_spi_alloc_host() so that there's no need to call
spi_controller_put() in the error path.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/spi/spi-xcomm.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/spi/spi-xcomm.c b/drivers/spi/spi-xcomm.c
index 063ce75af6504..5bbc250bc0534 100644
--- a/drivers/spi/spi-xcomm.c
+++ b/drivers/spi/spi-xcomm.c
@@ -248,7 +248,7 @@ static int spi_xcomm_probe(struct i2c_client *i2c)
 	struct spi_controller *host;
 	int ret;
 
-	host = spi_alloc_host(&i2c->dev, sizeof(*spi_xcomm));
+	host = devm_spi_alloc_host(&i2c->dev, sizeof(*spi_xcomm));
 	if (!host)
 		return -ENOMEM;
 
@@ -265,7 +265,7 @@ static int spi_xcomm_probe(struct i2c_client *i2c)
 
 	ret = devm_spi_register_controller(&i2c->dev, host);
 	if (ret < 0)
-		spi_controller_put(host);
+		return ret;
 
 	return spi_xcomm_gpio_add(spi_xcomm);
 }

-- 
2.45.2

