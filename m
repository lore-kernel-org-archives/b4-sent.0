From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 22 May 2024 14:54:06 +0200
Subject: [PATCH v2 2/2] iio: adc: ad9467: change struct members padding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240522-dev-ad9467-dma-v2-2-a37bec463632@analog.com>
References: <20240522-dev-ad9467-dma-v2-0-a37bec463632@analog.com>
In-Reply-To: <20240522-dev-ad9467-dma-v2-0-a37bec463632@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716382445; l=2382;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=KRf601UhH6cUyFxH9p8cxQJJFXZVEBFnvvguvfjDdPM=;
 b=GZQZBeGHXM+p4BKmPqY+cqZ4ADeNUriVSfpnwCF3qY2DjHTOMk4D0+Ks+oXyX7P++UEzSGd2F
 BGRXi8UwtN/DOnoxE3fUv2+aftC3XoUwQ9fjlcWbq9hurq33cvprYgt
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Using tabs and maintaining the start of the variables aligned is a pain and
may lead to lot's of unrelated changes when adding new members. Hence,
let's change things now and just have a simple space.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 40 ++++++++++++++++++++--------------------
 1 file changed, 20 insertions(+), 20 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 3571cfe0f9cc2..ec11437cac7e0 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -107,27 +107,27 @@
 #define AD9647_MAX_TEST_POINTS		32
 
 struct ad9467_chip_info {
-	const char		*name;
-	unsigned int		id;
-	const struct		iio_chan_spec *channels;
-	unsigned int		num_channels;
-	const unsigned int	(*scale_table)[2];
-	int			num_scales;
-	unsigned long		max_rate;
-	unsigned int		default_output_mode;
-	unsigned int		vref_mask;
-	unsigned int		num_lanes;
+	const char *name;
+	unsigned int id;
+	const struct iio_chan_spec *channels;
+	unsigned int num_channels;
+	const unsigned int (*scale_table)[2];
+	int num_scales;
+	unsigned long max_rate;
+	unsigned int default_output_mode;
+	unsigned int vref_mask;
+	unsigned int num_lanes;
 	/* data clock output */
-	bool			has_dco;
+	bool has_dco;
 };
 
 struct ad9467_state {
-	const struct ad9467_chip_info	*info;
-	struct iio_backend		*back;
-	struct spi_device		*spi;
-	struct clk			*clk;
-	unsigned int			output_mode;
-	unsigned int                    (*scales)[2];
+	const struct ad9467_chip_info *info;
+	struct iio_backend *back;
+	struct spi_device *spi;
+	struct clk *clk;
+	unsigned int output_mode;
+	unsigned int (*scales)[2];
 	/*
 	 * Times 2 because we may also invert the signal polarity and run the
 	 * calibration again. For some reference on the test points (ad9265) see:
@@ -138,10 +138,10 @@ struct ad9467_state {
 	 * at the io delay control section.
 	 */
 	DECLARE_BITMAP(calib_map, AD9647_MAX_TEST_POINTS * 2);
-	struct gpio_desc		*pwrdown_gpio;
+	struct gpio_desc *pwrdown_gpio;
 	/* ensure consistent state obtained on multiple related accesses */
-	struct mutex			lock;
-	u8				buf[3] __aligned(IIO_DMA_MINALIGN);
+	struct mutex lock;
+	u8 buf[3] __aligned(IIO_DMA_MINALIGN);
 };
 
 static int ad9467_spi_read(struct ad9467_state *st, unsigned int reg)

-- 
2.44.0

