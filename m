From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 31 Oct 2025 12:31:24 +0000
Subject: [PATCH v3 03/10] iio: dac: ad5446: Don't ignore missing regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251031-dev-add-ad5542-v3-3-d3541036c0e6@analog.com>
References: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
In-Reply-To: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761913895; l=1108;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=79iWfxVs1TX8tdmn9pCr0tJJuCMUrpn41+wz6b5CyUQ=;
 b=9Zu/i1mRQLXLEt/I6qllLVFJSMe/SKeICj4XiH8ahJA+1jXrz2pSvepmncfBByv4dii9YhzqK
 O0S9M4+vLYuCt++W3S3ii/cErobh0I30Eg5c0vp9DCIQWK9UXuYuJOA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the chip does not have an internal reference, do not ignore a missing
regulator as we won't be able to actually provide a proper scale for the
DAC. Since it's now seen as an error, flip the if() logic so errors are
treated first (which is the typical pattern).

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index de5e4e0e397e..5f9b6f82a981 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -253,10 +253,11 @@ static int ad5446_probe(struct device *dev, const char *name,
 	if (ret < 0 && ret != -ENODEV)
 		return ret;
 	if (ret == -ENODEV) {
-		if (chip_info->int_vref_mv)
-			st->vref_mv = chip_info->int_vref_mv;
-		else
-			dev_warn(dev, "reference voltage unspecified\n");
+		if (!chip_info->int_vref_mv)
+			return dev_err_probe(dev, ret,
+					     "reference voltage unspecified\n");
+
+		st->vref_mv = chip_info->int_vref_mv;
 	} else {
 		st->vref_mv = ret / 1000;
 	}

-- 
2.51.0

