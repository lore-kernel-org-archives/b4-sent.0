From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:09 +0000
Subject: [PATCH v4 04/12] iio: dac: ad5446: Don't ignore missing regulator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-4-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=1108;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=okuknmDZ8VnobvB5MdfQlpCEFH0waLrFc7eKB4aMwI8=;
 b=9t96c7asVOUQZb8RdHLBsepPuro1xeLexBVTVuuqtkEfKw2LterBxkynt0MfuPixJcYqKHZpO
 e1ctjkKfH1qCCkTqVeI7tFhhIzLp7CDDNNxsetxCVBDZS5zzst/BLBw
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
index c0a38f642451..cbe2a6862f10 100644
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

