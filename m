From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:50 +0100
Subject: [PATCH v2 11/13] iio: light: al3320a: Improve error handling with
 dev_err_probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-11-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=986; i=david@ixit.cz;
 h=from:subject:message-id; bh=ZDkoBVIulq1cvMnCXDseiCDdnOJkjxiu1pAE5heNCiI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA+9HVHS3Gw6TUynM2zoj665kSVRiBUCkb9H
 ihXRUBd0keJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPgAKCRBgAj/E00kg
 cqWNEADLu6eFtloKSuyFWtEppBrRsu1TKUXzpTfpo/P9eGjGYtMmCY0Jvm8naaouakGmp+nQkqa
 lzw0DvPSztb4ztCj69KIRtOufEq1grItt1iH15FENy8c1a8UK4r9MDAoeFWz3/XlgTHIyFvtm9g
 SDA269/5WKaOMn2Key85mDl8oED1heoTyjHsQC5SnAs/auP38xZakWlTDPEFrAjGluUpV9Gxi65
 9bAXXb2V98w6s+VvsQ45Lo5j38XglCvnslweAjfdyH6iqOEHqzKDtqASNlzLoEmX46AlYDMjKTe
 1V63VCeYVjifmVlC6nR+lkT5FXgW2tR8rgWqilsqieFxbpuqz2ny+KHgLPcQjaFU6UQqJnfKuGq
 bYWafQz3UCMpYZ/n5N9xEFelOnfIeBsHBXkV6vs2mT3dMCBHQ1IP8byxt34xelrKjHarDHPGPmi
 Wv0zr8Qz/Q7nhj3TtjyG+CiYamj1MIO93igJ2W8PWLC+WFPMGN4ujaq64jNAk0VYGDRgcTMlDJm
 xSUbtAVvJV+p6JGqrxuQflqdLFLLa8H0bIc/LGJBCqxllMcVhv/9q8NKbEDFJOOMQvKqkfWWYO3
 PJQHj4QJZjmN4yUbkwRparMw8qhksECejnPDuCp6z9CVsWZCPFj8YfjtSRhpaMM7j/Xios2QfHb
 0dwlvYQo9SuSueg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Slight simplification of the code.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index 1b2b0359ed5dad5e00d2fe584f8f3495c13c997e..1943e6f34a70b00b5d732dbf4ae6ccb4376303b7 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -206,14 +206,12 @@ static int al3320a_probe(struct i2c_client *client)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 
 	ret = al3320a_init(data);
-	if (ret < 0) {
-		dev_err(dev, "al3320a chip init failed\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to init ALS\n");
 
 	ret = devm_add_action_or_reset(dev, al3320a_set_pwr_off, data);
-	if (ret < 0)
-		return ret;
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add action\n");
 
 	return devm_iio_device_register(dev, indio_dev);
 }

-- 
2.49.0

