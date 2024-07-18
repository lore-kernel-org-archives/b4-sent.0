From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:37:48 +0200
Subject: [PATCH 02/22] iio: adc: dln2-adc: use new '.masklength' accessors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-2-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=1702;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=SVzVUJhUJEG0BkoeN3CF9y2OFfW7PnyRhClF65Q6WLY=;
 b=ZBWG1YfMAwcurvzBRn9mCDkOUHRVFtnp29Wq3GrNTMZpjHgzT1+Pq/XL4Q9LpOogmNRV8K5Np
 pVnbhPOzkJoA70sar1d44x+XLZD55Eipc2NeXWJ20r9v0YzIK9nB4XA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of iio_get_masklength) and iio_for_each_active_channel() to
access '.masklength' so it can be annotated as __private when there
are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/dln2-adc.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/adc/dln2-adc.c b/drivers/iio/adc/dln2-adc.c
index 06cfbbabaf8dc..de7252a10047d 100644
--- a/drivers/iio/adc/dln2-adc.c
+++ b/drivers/iio/adc/dln2-adc.c
@@ -108,7 +108,7 @@ static void dln2_adc_update_demux(struct dln2_adc *dln2)
 	dln2->demux_count = 0;
 
 	/* Optimize all 8-channels case */
-	if (indio_dev->masklength &&
+	if (iio_get_masklength(indio_dev) &&
 	    (*indio_dev->active_scan_mask & 0xff) == 0xff) {
 		dln2_adc_add_demux(dln2, 0, 0, 16);
 		dln2->ts_pad_offset = 0;
@@ -117,9 +117,7 @@ static void dln2_adc_update_demux(struct dln2_adc *dln2)
 	}
 
 	/* Build demux table from fixed 8-channels to active_scan_mask */
-	for_each_set_bit(out_ind,
-			 indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, out_ind) {
 		/* Handle timestamp separately */
 		if (out_ind == DLN2_ADC_MAX_CHANNELS)
 			break;
@@ -541,7 +539,7 @@ static int dln2_adc_triggered_buffer_postenable(struct iio_dev *indio_dev)
 
 	/* Assign trigger channel based on first enabled channel */
 	trigger_chan = find_first_bit(indio_dev->active_scan_mask,
-				      indio_dev->masklength);
+				      iio_get_masklength(indio_dev));
 	if (trigger_chan < DLN2_ADC_MAX_CHANNELS) {
 		dln2->trigger_chan = trigger_chan;
 		ret = dln2_adc_set_chan_period(dln2, dln2->trigger_chan,

-- 
2.45.2

