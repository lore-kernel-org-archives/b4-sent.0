From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 28 Apr 2026 18:02:18 +0100
Subject: [PATCH v3 03/11] iio: dac: ad5686: acquire lock when doing
 powerdown control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-ad5686-fixes-v3-3-9cff7bd67a15@analog.com>
References: <20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com>
In-Reply-To: <20260428-ad5686-fixes-v3-0-9cff7bd67a15@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777395737; l=1335;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=1oS02JnTrI5wiIzSz+QkF/MekEEwrISkavx8yLsCZCI=;
 b=U4qQdQd8KE5MMad2EyvQU7MgouJ7TgeDBvOU8hzO3bV2BdfaahgesjuoWCg5hqhiRGLVYAOvd
 5WhZ6l++EZmB3UgOvy4lu89E+AvwWf9fe8s0u444nmfdkAeh9qxWc++
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Protect write access of pwr_down_mode and pwr_down_mask fields with
existing mutex lock. Each channel exposes their own attributes for
controlling powerdown modes and powerdown state. This fixes potential
race conditions as those functions perform non-atomic read-modify-write
operations to those pwr_down_* fields. This issue exists since the
ad5686 driver was first introduced.

Fixes: c2f37c8dcadc ("iio: dac: New driver for AD5686R, AD5685R, AD5684R Digital to analog converters")
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5686.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/iio/dac/ad5686.c b/drivers/iio/dac/ad5686.c
index 076fe8b8bd85..69358dd66cbc 100644
--- a/drivers/iio/dac/ad5686.c
+++ b/drivers/iio/dac/ad5686.c
@@ -39,6 +39,8 @@ static int ad5686_set_powerdown_mode(struct iio_dev *indio_dev,
 {
 	struct ad5686_state *st = iio_priv(indio_dev);
 
+	guard(mutex)(&st->lock);
+
 	st->pwr_down_mode &= ~(0x3 << (chan->channel * 2));
 	st->pwr_down_mode |= ((mode + 1) << (chan->channel * 2));
 
@@ -77,6 +79,8 @@ static ssize_t ad5686_write_dac_powerdown(struct iio_dev *indio_dev,
 	if (ret)
 		return ret;
 
+	guard(mutex)(&st->lock);
+
 	if (readin)
 		st->pwr_down_mask |= (0x3 << (chan->channel * 2));
 	else

-- 
2.43.0

