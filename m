From: Andrea Amer <and.amer@gmail.com>
Date: Fri, 16 Oct 2026 13:00:20 +0200
Subject: [PATCH v2] iio: afe: rescale: always expose offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-iio-rescale-offset-v2-1-02c825967139@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMMD0moC/32NQQqDMBBFryKzbooTY4pd9R7FRZpMdECNJCItk
 rs39QDlr96H//4BiSJTgnt1QKSdE4elgLxUYEezDCTYFQZZS401SsEcRKRkzUQieJ9oEwplq0z
 TvLTTUIZrJM/vU/rsC4+cthA/58eOv/avbkdRoshh29067+VjmA1PVxtm6HPOX08tp+S0AAAA
X-Change-ID: 20261012-iio-rescale-offset-41254a33b6d6
To: Peter Rosin <peda@lysator.liu.se>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, Andrea Amer <and.amer@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792148437; l=1534;
 i=and.amer@gmail.com; s=20261012; h=from:subject:message-id;
 bh=smDOZf3s0TRH8qOItOidEFI5I1QOKi3ZjzCMwcFZDI8=;
 b=UR/i6E6rwteZ0Erdlwc7kK0TfnZAzzWBdHcBVSiQNaCkKvutisIOPQoqdlDbpXTGqKVvuXrua
 8hVFvwQCq4KCzhsirlUCUM73+FI3tMml7m9wjmB4yKv3FiF/pmCQ/7Z
X-Developer-Key: i=and.amer@gmail.com; a=ed25519;
 pk=TiMK202FvcPM+yKGkAI4hsAZA7QkwyEgru97PAFa4pg=
X-Endpoint-Received: by B4 Relay for and.amer@gmail.com/20261012 with auth_id=1165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A rescale channel advertises IIO_CHAN_INFO_OFFSET only when its own
offset is non-zero. A child rescale therefore hides a source offset,
and consumers apply raw * scale and drop it. rescale_read_raw() already
folds the source offset in, so expose the attribute in every case.

Fixes: a29c3283653b ("iio: afe: rescale: add offset support")
Signed-off-by: Andrea Amer <and.amer@gmail.com>
---
Changes in v2:
- Keep the IIO_CHAN_INFO_SCALE line unchanged (Andy Shevchenko)
- Link to v1: https://lore.kernel.org/r/20261012-iio-rescale-offset-v1-1-14ed15979ff2@gmail.com
---
 drivers/iio/afe/iio-rescale.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/afe/iio-rescale.c b/drivers/iio/afe/iio-rescale.c
index 3a6a09ffa5267ddfd5131fbd04a5df928836589d..4639a67ea462bf5c29603783a6f230d769fb02b0 100644
--- a/drivers/iio/afe/iio-rescale.c
+++ b/drivers/iio/afe/iio-rescale.c
@@ -301,11 +301,9 @@ static int rescale_configure_channel(struct device *dev,
 	}
 
 	chan->info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
+		BIT(IIO_CHAN_INFO_OFFSET) |
 		BIT(IIO_CHAN_INFO_SCALE);
 
-	if (rescale->offset)
-		chan->info_mask_separate |= BIT(IIO_CHAN_INFO_OFFSET);
-
 	/*
 	 * Using .read_avail() is fringe to begin with and makes no sense
 	 * whatsoever for processed channels, so we make sure that this cannot

---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261012-iio-rescale-offset-41254a33b6d6

Best regards,
-- 
Andrea Amer <and.amer@gmail.com>

