From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:40 +0100
Subject: [PATCH v2 01/13] iio: light: al3010: Use unsigned int for the
 indexing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-1-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=695; i=david@ixit.cz;
 h=from:subject:message-id; bh=10RW+w/I6ilKLev9SA61EnDHTOc4Fb07ecKF8eR6P2k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA9nvfVsg54dt4iRBKJw7MJR9M/9KEpGtost
 aKxsPesBrKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPQAKCRBgAj/E00kg
 cjiVD/9/dzEsrY+MLXY7m/lJf+McDISs1NNYlOQTF0sQLMx+jQueAxoG6UVqyrPN2O6w5zhISxt
 Zq92t+hu3JqLGS9sAMx974Kpeix1Ja4MFblYtXygFd4XEYEWI+gcZYzHZl2KbE8xKBlyc/mEN2+
 oD67aKLjyJg6/G6v5IfbPc3B7vJzBf2/lMNUO4B00wuwUWfeaCyFhCurPTHMvdaT61IBo/6m12n
 IY2FLCU1yokyDskmoOEDUDGd3Q30mp+sSGlZ4fsuy34fvYMksEkFmL1EsyhgYLeVNcN5DM1C4jO
 n2dVJf1HDHpgQSYrvOVx/PxXpvmqglUuQCe6fedNzqSCqD6bSHxWYbQPzEVg7CTb5bnHYOu4H9S
 Lb3W+oOf4hpcIfoNDlt4O3oCPdr24whirSwtFnrEYmy3kerS5N3FnapngONcJGiWbASdRNfsNhu
 6H8MqY7WF3jnKSSbhQYPIaLasr6T5NJ+3OXwXV/udEqlNDB1HEHshI9q80Nyt7n8K90jR/qwQYT
 JeZfwk6YypAwGqM8zeuPVO5Kn3RhSAnPL1Nj9IyBZ6RZCViLaohKrCaWcAC1suExEy1mPyvsei3
 rJ4k2tO2MTi5sJ8OooIb9z5SDwacIJZW1B2CX8Lvs6juNa8+yYzncc+LTI057Qz59ZF5KU6bn77
 rew6XGe6F7cTOHw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The integer is used as array index which cannot be negative.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 7cbb8b203300907a88f4a0ab87da89cabdd087f3..4c2fd88ab32cd73f4735b0fa3014af084037c94d 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -145,7 +145,7 @@ static int al3010_write_raw(struct iio_dev *indio_dev,
 			    int val2, long mask)
 {
 	struct al3010_data *data = iio_priv(indio_dev);
-	int i;
+	unsigned int i;
 
 	switch (mask) {
 	case IIO_CHAN_INFO_SCALE:

-- 
2.49.0

