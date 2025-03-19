From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:49 +0100
Subject: [PATCH v2 10/13] iio: light: al3010: Improve al3010_init error
 handling with dev_err_probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-10-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=818; i=david@ixit.cz;
 h=from:subject:message-id; bh=U+gyu2giS4hLLAaP3knPJNMAi2dd0lLS/xGNscKmGCc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA+6UW4pTZ7TSIE2lofczNz+g9UJ/qu6PDg5
 aBmh+cDYR6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPgAKCRBgAj/E00kg
 co5NEACXcv0zPgnlpV8JIFGudofxcsi1tp9n1jUHFFlcZ9D7hvRgidJZqmmX6P1/XMYvaHW0PLM
 0kg8ZEFUy4YmewBfM/FUMIygQLM7HjiwyQ3VP/TOelKD37GA6CORJ7WLo7WifL5oRuNjWcAmS/X
 3Lz7/Lr3rCG1ohB8KCRIituClAVaJD2V/my1pxNmkqlmec0U2pFRo7fbeDn1tmlmPtyYrUw7M48
 SlIsv1kQWukdo/zvIBadYuIzE4H415FlTKDv1mzcKzW5syFsrzMgbAeKOZCixZhMJyjToch5vmv
 mdGAsXiuHIZjNYCVUrAksdSeOsJzFViBMBaUfgdW14fj2iFttJ811vIxFheMYiOggTGpeK/zZDP
 wDZ3Q3269sLlwbP472fOl1RZ56G1lz4cKcQhB4pUN5vdWIH/ytWMoKzANcJb39lg7xffpJaHgoh
 0j3xSAtyoWofcYxToFYCtl6WZJfwO3rW+Pets6Dw+jHlHk3ZOGx8jK7QkFIvGpXDezprWWhKafD
 +7WSUCET5aON3NPOpynrSp0YZw4eTCdQqkyNHiVE5iCGVRw9cGcCWGulO5rdnkKcINfbWQLKwZ2
 JrcrL9CR7vQjTxqeOQkM+bcp1k/kJDe68r3TdLN4mejN+XORme3kA2gINXte9Z7HDBUEix7IRoP
 AhMxf/nKn9vArUQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Slight simplification of the code.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 8098c92c9572befe92d00ef0785ded5e1a08d587..af7ed028259837f2232f30072b87cc0da7c77f37 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -184,10 +184,8 @@ static int al3010_probe(struct i2c_client *client)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 
 	ret = al3010_init(data);
-	if (ret < 0) {
-		dev_err(dev, "al3010 chip init failed\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to init ALS\n");
 
 	ret = devm_add_action_or_reset(dev, al3010_set_pwr_off, data);
 	if (ret)

-- 
2.49.0

