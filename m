From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 26 Apr 2026 09:38:09 +0100
Subject: [PATCH 08/10] iio: dac: ad5686: fix input raw value check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260426-ad5686-fixes-v1-8-7c946a77794e@analog.com>
References: <20260426-ad5686-fixes-v1-0-7c946a77794e@analog.com>
In-Reply-To: <20260426-ad5686-fixes-v1-0-7c946a77794e@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777192698; l=1053;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Jyqj3+FFKyypdm39jK5VmyJy5lEuvWoM3X8faV9LnaQ=;
 b=J5VdC3SHKabbzhvICo8tYevq7BRLLWVqWZ3f9aqHns8S2D7KAC0WikGTH7VKArqdonMt1rbpW
 gyG88+gu0leD+oMUTrOAa0WpB1KnHzVdHwNbmrQFfxSnBjEogV60WvB
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use in_range() to fix range check for input raw value, which is off by
one, i.e., for a 10-bit DAC the max valid value is 1023, but 1 << 10
equals 1024, which passes the previous check, allowing an out-of-range
write. The issue exists since the ad5686 driver was first introduced.

Fixes: c2f37c8dcadc ("iio: dac: New driver for AD5686R, AD5685R, AD5684R Digital to analog converters")
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 040a24c62c9a..ab498ec2ed5c 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -186,7 +186,7 @@ static int ad5686_write_raw(struct iio_dev *indio_dev,
 
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:
-		if (val > (1 << chan->scan_type.realbits) || val < 0)
+		if (!in_range(val, 0, 1 << chan->scan_type.realbits))
 			return -EINVAL;
 
 		return st->write(st, AD5686_CMD_WRITE_INPUT_N_UPDATE_N,

-- 
2.43.0

