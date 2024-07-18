From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 18 Jul 2024 15:38:01 +0200
Subject: [PATCH 15/22] iio: light: si1145: use new '.masklength' accessors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240718-dev-iio-masklength-private2-v1-15-8e12cd042906@analog.com>
References: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
In-Reply-To: <20240718-dev-iio-masklength-private2-v1-0-8e12cd042906@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Andreas Klinger <ak@it-klinger.de>, 
 Song Qiang <songqiang1304521@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721309903; l=1394;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ydCEkP8JsRVtoKR9bEq7QSVO3KXJv8WNwFnv2eEpBeY=;
 b=gZ6IUQPm0/RNFe4OkVKzRf1jtalaFetYLzAUqhSgt7EOB8gDOEdPWgEnTdO+raWTHyqKzp8pr
 e72dFK821ICCkLHVQj0FpYw962mT8CAa63j40Y2vxjthY6FmoN9f7SG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of iio_get_masklength) and iio_for_each_active_channel() to
access '.masklength' so it can be annotated as __private when there
are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/light/si1145.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/si1145.c b/drivers/iio/light/si1145.c
index 77666b780a5c5..66abda021696a 100644
--- a/drivers/iio/light/si1145.c
+++ b/drivers/iio/light/si1145.c
@@ -465,11 +465,10 @@ static irqreturn_t si1145_trigger_handler(int irq, void *private)
 			goto done;
 	}
 
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		int run = 1;
 
-		while (i + run < indio_dev->masklength) {
+		while (i + run < iio_get_masklength(indio_dev)) {
 			if (!test_bit(i + run, indio_dev->active_scan_mask))
 				break;
 			if (indio_dev->channels[i + run].address !=
@@ -514,7 +513,7 @@ static int si1145_set_chlist(struct iio_dev *indio_dev, unsigned long scan_mask)
 	if (data->scan_mask == scan_mask)
 		return 0;
 
-	for_each_set_bit(i, &scan_mask, indio_dev->masklength) {
+	for_each_set_bit(i, &scan_mask, iio_get_masklength(indio_dev)) {
 		switch (indio_dev->channels[i].address) {
 		case SI1145_REG_ALSVIS_DATA:
 			reg |= SI1145_CHLIST_EN_ALSVIS;

-- 
2.45.2

