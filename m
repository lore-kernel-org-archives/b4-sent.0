From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:44 +0100
Subject: [PATCH v2 05/13] iio: light: al3010: Abstract device reference in
 the probe function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-5-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1322; i=david@ixit.cz;
 h=from:subject:message-id; bh=X7k3nG8St4YffEhl0mBYetKomz7otdLVmRWRQD0F640=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9XOyrnm7ZpJDYqVGomOPKxao6IZma8EtDZ
 LIuHwfzhOKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 cjCCD/9OmxKSxOpC69ZSJCmuOzJpi11TytIbokCL99Grr8+Nxdc8ZzZBOL9aXg5zNHa01dabyPh
 rC7qX7buuUyjEFxtm3gyIlPKU6qUNL6hsaIaWC02/fVX5rUtxgUhIauJ+4yYjHqaL/xJxSw1o2W
 aTXsFAW36ACb2K3A01KnFwWDYx2FEDMGxK/qdmMBfodcbx3SiAo0JT7LLlVvbaVaDSJgQNeRY3S
 OjLD0Q7og92GtxVKZk4u7/cZp5MJQzIXYFYRZl9q0jgz8rw4KePXGhbQzpZ2Lqw6xXTe3l+cJwU
 sYw2CYJmJdak3poNhl6Epme6VMhL+trkJPl+5UC8Yel2USEvZ7/a9+dfSpB63E5Nf6OVUWBJanF
 Qk9En5mPoNAYuuyMawqEyIKBwfeV0HDAuYY6zNI3SPp5ew4Ay4/zztTVdDToloP3ohZ33dEgDxa
 NjiwU72sBhHGi0QYNxSkNk60Z30RRSEJVM+0hlbSv1VBhJSIbvjGl8WzVmKofi+f2wvsggPQHUY
 aJIzZ0H3K9i6LH/J96HxRZbXl3uao1P006Ux9o3Yr+Nb8Lxhocis++NMUkACwMP5Z1FXAIMTTsG
 Xrq2MUWQ2sBCsgnJK19PlBV0jsUyxp9uwypMdkaY9SfKJw2bQoVFkx6ved3KadkKJQMqDJ9HRPq
 87wvMjZ8JBMh41Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local variable reducing redundancy and improving readability.

No functional changes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 7fe91049b55e57558aef69d088d168437a6819ec..c8f528f3636a2eb0f0c9586da64a6560d4b42e29 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -170,10 +170,11 @@ static const struct iio_info al3010_info = {
 static int al3010_probe(struct i2c_client *client)
 {
 	struct al3010_data *data;
+	struct device *dev = &client->dev;
 	struct iio_dev *indio_dev;
 	int ret;
 
-	indio_dev = devm_iio_device_alloc(&client->dev, sizeof(*data));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*data));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -189,11 +190,11 @@ static int al3010_probe(struct i2c_client *client)
 
 	ret = al3010_init(data);
 	if (ret < 0) {
-		dev_err(&client->dev, "al3010 chip init failed\n");
+		dev_err(dev, "al3010 chip init failed\n");
 		return ret;
 	}
 
-	return devm_iio_device_register(&client->dev, indio_dev);
+	return devm_iio_device_register(dev, indio_dev);
 }
 
 static int al3010_suspend(struct device *dev)

-- 
2.49.0

