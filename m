From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 31 Oct 2025 12:31:28 +0000
Subject: [PATCH v3 07/10] iio: dac: ad5446: Make use of devm_mutex_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251031-dev-add-ad5542-v3-7-d3541036c0e6@analog.com>
References: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
In-Reply-To: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761913895; l=695;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=TcScp9YMNX1T1uCOCkW6UV53t32jVxdLnSxBaxEQVpg=;
 b=fqW9yst1QG5QptxYiIou7zHVZGbfsEuqlacQaljawvXKwU+PJjZmJ9mq4LYXZPo7W3DQY4EJZ
 OKJkNLl3Io/BDkzRZwYSOGFakyp1znpF3QQH65TsOJQH5W3Aexrsp7G
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use devm_mutex_init() which is helpful with CONFIG_DEBUG_MUTEXES.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index 790e24770062..d9fc69e1039f 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -184,7 +184,9 @@ int ad5446_probe(struct device *dev, const char *name,
 	indio_dev->channels = &st->chip_info->channel;
 	indio_dev->num_channels = 1;
 
-	mutex_init(&st->lock);
+	ret = devm_mutex_init(dev, &st->lock);
+	if (ret)
+		return ret;
 
 	st->pwr_down_mode = MODE_PWRDWN_1k;
 

-- 
2.51.0

