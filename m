From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:45 +0100
Subject: [PATCH v2 06/13] iio: light: al3320a: Abstract device reference in
 the probe function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-6-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1532; i=david@ixit.cz;
 h=from:subject:message-id; bh=Ct1gfcrjZUKbkM919cRcq2ZoAee3rgE77Wd7D0kN4IQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9d5MI7y5r0Kp+Il39GDvhw+GAXO+1U68D8
 cpoGkCO4B2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 cgrED/0aXuYXLYx7Lx1WaDZQ9DPGyQQuMmWIU6B2lm3T7Wc+VGSAv1FN+d+t1eXoosMwqbSgztF
 ixW6pL4d4YJOsCaYg1FWaWPeNKAo4lxXkMrAinWNqCZck2RohshLweIkbQqG/q1C0vNJeswbo6p
 +6XsHms6myzLQpEZPPkkYKReWBgsOfA/bq38nWXjsAEMMq6hAw/7szTtMsug50DhhKXOeSch0fZ
 M9CIGIcDVlLAPb0wWjWYsmvSuGZ1nlwMLQC+l4j6jEkyzkTzlBP6ByzrlOgArYL/EixHBGgelEj
 9WNbi10ESDReQnx43zVcfX9Auffypjg7Q9ZxZjhk/g2NzySAG/yNJnWRcQPVwqoF0YfgZ1Sd94W
 Flyl+sXMEBPrrOdcJI89H8Q3s+4HM68spBPQHy8B2au5ICMw5woSMgp5H61xN809rPVPXDNvH35
 DoPYHbd7epzP6g0qaaphNylFXVzYFFbHQ5tH0L0inYRbYSa9JIaXpyv9l4rXp+mb+nOF2WT+GK6
 heDYoDCpI3oluivR4XJnzGiFXIKVly6ygBUyBiyTA+iTngC9N3UfBF654wnpnjJUc7372iXLkDv
 NHdsGIvb02tAHf2/RAopJZ/dr5hi2zhVD7UKPXnRbfMtMfvlaXqEe4/Ft1nGpORJP+2jPh+l2ol
 kDa/bDqdbRBqOag==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a local variable reducing redundancy and improving readability.

No functional changes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 11 +++++------
 1 file changed, 5 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index 93416f3bd7fbb0a75bef17949725d0d40b9b93ea..9817cfe8ae18a8e27c82e7362481ebd32a41f8ec 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -188,10 +188,11 @@ static const struct iio_info al3320a_info = {
 static int al3320a_probe(struct i2c_client *client)
 {
 	struct al3320a_data *data;
+	struct device *dev = &client->dev;
 	struct iio_dev *indio_dev;
 	int ret;
 
-	indio_dev = devm_iio_device_alloc(&client->dev, sizeof(*data));
+	indio_dev = devm_iio_device_alloc(dev, sizeof(*data));
 	if (!indio_dev)
 		return -ENOMEM;
 
@@ -207,17 +208,15 @@ static int al3320a_probe(struct i2c_client *client)
 
 	ret = al3320a_init(data);
 	if (ret < 0) {
-		dev_err(&client->dev, "al3320a chip init failed\n");
+		dev_err(dev, "al3320a chip init failed\n");
 		return ret;
 	}
 
-	ret = devm_add_action_or_reset(&client->dev,
-					al3320a_set_pwr_off,
-					data);
+	ret = devm_add_action_or_reset(dev, al3320a_set_pwr_off, data);
 	if (ret < 0)
 		return ret;
 
-	return devm_iio_device_register(&client->dev, indio_dev);
+	return devm_iio_device_register(dev, indio_dev);
 }
 
 static int al3320a_suspend(struct device *dev)

-- 
2.49.0

