From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Thu, 16 Oct 2025 07:20:38 +0200
Subject: [PATCH v4 1/2] iio: humditiy: hdc3020: fix units for temperature
 and humidity measurement
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-hdc3020-units-fix-v4-1-2d9e9f33c7b1@liebherr.com>
References: <20251016-hdc3020-units-fix-v4-0-2d9e9f33c7b1@liebherr.com>
In-Reply-To: <20251016-hdc3020-units-fix-v4-0-2d9e9f33c7b1@liebherr.com>
To: Javier Carrasco <javier.carrasco.cruz@gmail.com>, 
 Li peiyu <579lpy@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Chris Lesiak <chris.lesiak@licorbio.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760592043; l=1338;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=1Poi65ufYWSrgXpM9TeB84HDWnd8hM9UVI5WIoXbC1w=;
 b=/NDAEYSPTNjccxbXM9CerHi6+IMRbOg6qgd010QRi76D56k3YI89lWuwidn4hWmaugRnufeq7
 K2+aq1wQVoQCO8BNyg3zFGxT7+q6W04gbsZ9b966LjzNtQuZobs5crS
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the ABI the units after application of scale and offset are
milli degrees for temperature measurements and milli percent for relative
humidity measurements. Currently the resulting units are degree celsius for
temperature measurements and percent for relative humidity measurements.
Change scale factor to fix this issue.

Fixes: c9180b8e39be ("iio: humidity: Add driver for ti HDC302x humidity sensors")
Reported-by: Chris Lesiak <chris.lesiak@licorbio.com>
Suggested-by: Chris Lesiak <chris.lesiak@licorbio.com>
Reviewed-by: Javier Carrasco <javier.carrasco.cruz@gmail.com>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 drivers/iio/humidity/hdc3020.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/humidity/hdc3020.c b/drivers/iio/humidity/hdc3020.c
index ffb25596d3a8bad01d1f84a9a972561266f65d76..8aa567d9aded9cab461f1f905b6b5ada721ba2f0 100644
--- a/drivers/iio/humidity/hdc3020.c
+++ b/drivers/iio/humidity/hdc3020.c
@@ -301,9 +301,9 @@ static int hdc3020_read_raw(struct iio_dev *indio_dev,
 	case IIO_CHAN_INFO_SCALE:
 		*val2 = 65536;
 		if (chan->type == IIO_TEMP)
-			*val = 175;
+			*val = 175 * MILLI;
 		else
-			*val = 100;
+			*val = 100 * MILLI;
 		return IIO_VAL_FRACTIONAL;
 
 	case IIO_CHAN_INFO_OFFSET:

-- 
2.39.5

