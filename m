From: David Heidelberg <david@ixit.cz>
Date: Sat, 08 Mar 2025 21:00:58 +0100
Subject: [PATCH 1/4] iio: light: al3320a: Drop deprecated email for Daniel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-al3010-iio-regmap-v1-1-b672535e8213@ixit.cz>
References: <20250308-al3010-iio-regmap-v1-0-b672535e8213@ixit.cz>
In-Reply-To: <20250308-al3010-iio-regmap-v1-0-b672535e8213@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=718; i=david@ixit.cz;
 h=from:subject:message-id; bh=MXlQAzTdWxMSPXOYvO5LE/IyoymDgDTuIpV9wQjHRSE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzKJUrpA+Vsl85k9Ww3JP+vnbuBDlJARo0UKqw
 1vhlvIi0N2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8yiVAAKCRBgAj/E00kg
 ctATEACy4Yq7TFEh4DDq8NTYkhFhK6h18KSZ0BvGfh5PmB+ooHFDyjK5j7ylSBs/Mlw8iyEwFIG
 JBV3ENRfcGYFM+LeoD7cSKUfNH67TKv+GPJljp0LD4YEj8iMPQ/fg21lZG9hqez6qdqGqQxwPej
 XK8ijqON8qhuSXkVDR2Bn5P7+70M+nztt6UkRtDrZSBN1NmhqT7aB2AVrVUF65qjS8HtJRcETgF
 VzEqEz/neDPTnBjfI99ZgVOV0bm5naIbWnWUzifMpVe21gG4Vhv3UmjIuwwi/nQJs5NMUT1L5Ee
 liPypRACoJxYYzP2aezFLRZs25Jq8r+LKbWcbTVOOMQ5VUAmtHfW7hFAX5CiZfLvgoN4vitPY/X
 3++mTV1n9TePORRA6f/HCSAcDiqeQ4XeceRK2IIr3S7w10dKFiJ/bQFkPmyCupccvGbeXy2vhMF
 NIiUj2POZr5z1CtsEygeEY75tt2Gbl2RlJ4M0fKKmeXUHekF7wLBh33kv/zg0b3BkDZ16zsU6o4
 NpPSLpgKwlgRFOq0uRV52IPD8bnGdzzl9V0ONgj+0nAdn6TUtiPuULAoc3AkyeoAh3CEdtvAEAn
 KHMiVBhSRKtc3pBsY4Ck9rAj/LID2pQ66yhAGEAQ7ok8xuMfZIeS2+hyfn7YP3oqohIziRGJI+u
 x+Pbx/diuiXI7YA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

He no longer works at Intel.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index 497ea3fe337775b07efdfc56c80beb1aa55e394c..d34a91fdafa0affad4665d995e1f66d2aaa0373b 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -266,6 +266,6 @@ static struct i2c_driver al3320a_driver = {
 
 module_i2c_driver(al3320a_driver);
 
-MODULE_AUTHOR("Daniel Baluta <daniel.baluta@intel.com>");
+MODULE_AUTHOR("Daniel Baluta");
 MODULE_DESCRIPTION("AL3320A Ambient Light Sensor driver");
 MODULE_LICENSE("GPL v2");

-- 
2.47.2

