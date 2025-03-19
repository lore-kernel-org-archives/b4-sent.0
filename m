From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:43 +0100
Subject: [PATCH v2 04/13] iio: light: al3320a: Remove DRV_NAME definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-4-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1334; i=david@ixit.cz;
 h=from:subject:message-id; bh=podRMdd7qcZVHdZFZlFuKdLaKGh8xBj/PEa8jmahNxc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9cxcPFjtvjXTo2zRB3fD1q7ZuoiU+RRJno
 RP4FiMUKOWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 chtoD/0UL3tEWdE/eR7ZJj3B2TYv5nY9R1jIfhmtSA6d7/vWvxDnZlTctMQFuEC+Sw7TSPboe/H
 wSRNval/DE5ZmtGULxquuCHXWl2npgbGVKqmos5/HXdbGzCx+2UXehtGn9TaQWRlVY0TbY6i3yS
 EkdTJdZ6mMYDdMjDOsokHk+0rDg9/y+0gcnFJEgxFKejXRRbitjNffGHH5c+If21LpoQX6+Q1NG
 VB4gcJtwOW3h3aqM6mYjiWhWB5CqF+bMKk/iVE8LsesT9+AWTAnSBk5x21RlN/LlV5HnG487LRZ
 OwKMuqjXq0riAJPGZrN3GZjDZZt8Esmuj+ULKe2mM/Zp1/AKaU3PCSSS3v+O6AQYLfjz88OiDW9
 ssyU8OVnWm9rPtXOdTJH75sLgxLA8WIesECZz7rPxXbX+RSRfkmiX8m5OSQMMuQz83CZGhp8BD0
 lpYCYn7K5BgTkFbuB1TCZKsYem83He3euoQ3M4AiYvXpDnrlUUrtvN9amkuwMVA9em6vMDvvZJe
 AoCzvCmGH4qJMvfFgKPANfoRVx958VFOAdrfZQcj/EZqExzAPkHnZs1HOFIM7cm0j8v7oLXGNXs
 ImFkn6ODHCrPeE4/BsFivr5XgdsoIvulsMLG9nrzgTDP2349wSx11ZmQeao9bghuF8h3XjdVfC8
 Rrve+tcAJlETOAg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver name should be passed directly.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index bceda71517c8180dff76db311aa3591ab9846156..93416f3bd7fbb0a75bef17949725d0d40b9b93ea 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -20,8 +20,6 @@
 #include <linux/iio/iio.h>
 #include <linux/iio/sysfs.h>
 
-#define AL3320A_DRV_NAME "al3320a"
-
 #define AL3320A_REG_CONFIG		0x00
 #define AL3320A_REG_STATUS		0x01
 #define AL3320A_REG_INT			0x02
@@ -202,7 +200,7 @@ static int al3320a_probe(struct i2c_client *client)
 	data->client = client;
 
 	indio_dev->info = &al3320a_info;
-	indio_dev->name = AL3320A_DRV_NAME;
+	indio_dev->name = "al3320a";
 	indio_dev->channels = al3320a_channels;
 	indio_dev->num_channels = ARRAY_SIZE(al3320a_channels);
 	indio_dev->modes = INDIO_DIRECT_MODE;
@@ -255,7 +253,7 @@ MODULE_DEVICE_TABLE(acpi, al3320a_acpi_match);
 
 static struct i2c_driver al3320a_driver = {
 	.driver = {
-		.name = AL3320A_DRV_NAME,
+		.name = "al3320a",
 		.of_match_table = al3320a_of_match,
 		.pm = pm_sleep_ptr(&al3320a_pm_ops),
 		.acpi_match_table = al3320a_acpi_match,

-- 
2.49.0

