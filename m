From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:41 +0100
Subject: [PATCH v2 02/13] iio: light: al3320a: Use unsigned int for the
 indexing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-2-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=703; i=david@ixit.cz;
 h=from:subject:message-id; bh=ynRSZu6nJx2UyMC/JZCn2Zq/vADVq3GqxbyApWvpw90=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9h4KIyY+7mFaql0PaaN5PNdcRvG54s2agu
 Skraz0efHKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 cgB0EAC99yluiJrwzBdA3295VR1ghmmPqKqo3Kl7bxmKVdCv58MD418/Olkv3lQsF+Q5vbaktUw
 d5E6TaZG3blEcVIVU3XVzDHzE2Dss3vsVlngwO8m71fNCvPr2q4b5xo95SvHDL2i/8ihveYdgbd
 avPvXf8PlcAS2uxpsGAhPUkY9D/3qOjkyI9xZF7t9WMqgyMvAUsCZK5TIijGMGTA82Li5G3qYER
 IPTrkKnthER17g5HNdNXvYm94RWaMZ9q4xzP0zhOiTi7CfZr14s4vwoJes0k32IWfqsmvq3yxSt
 S4HaBucpBGazvYHriPStmCbKMqz+9Ey0Apq+vcNhYmAqMTNY+zgJduWt0LllHg7EQwkMdG8I9WA
 ZfxsQaQYx721hQygeRkrWSNTfVVUQXSCBlSqEoDfsYojOJMjuhE4K+oG34cpq5veQmSo9s/NlvH
 afBMNExYEqLUWWLcOh56qms9IFASDKmR/GuVooFQButX8KIcZm3DaAHBN591+3WhU5JWKpAX6gd
 bSkY+/h02Yuv7c36of7FsHw0EzZpBpedWhR4Yydn5xkdGTVHoFpP89aR+DwBhAtyzl8rNu0Zf2q
 G+d5+nJY1kPvgNQ3bC2CYkePeZ3BDhiZ/gWdps8uxwhoN8L+7ygbd6E1NqrlGZ8gM2MvfxoIO+w
 EfKmAaDyuAFsxVQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The integer is used as array index which cannot be negative.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index 497ea3fe337775b07efdfc56c80beb1aa55e394c..bceda71517c8180dff76db311aa3591ab9846156 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -163,7 +163,7 @@ static int al3320a_write_raw(struct iio_dev *indio_dev,
 			     int val2, long mask)
 {
 	struct al3320a_data *data = iio_priv(indio_dev);
-	int i;
+	unsigned int i;
 
 	switch (mask) {
 	case IIO_CHAN_INFO_SCALE:

-- 
2.49.0

