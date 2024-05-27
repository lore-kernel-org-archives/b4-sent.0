From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Subject: [PATCH v2 0/5] AD7173 fixes
Date: Mon, 27 May 2024 18:19:48 +0300
Message-Id: <20240527-ad7173-fixes-v2-0-8501b66adb1f@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJSkVGYC/3WMyw7CIBBFf6WZtRhm+sC46n+YLggMLYmCAUM0D
 f8udu/y3JtzdsicPGe4djskLj77GBrQqQOz6bCy8LYxkKRBjoRCW4WqF86/OYuBiUctJ2RH0JR
 n4uNoxm1pvPn8iulz1Av+1j+hgkKKC05ojHK9tjjroO9xPZv4gKXW+gVY93PUqQAAAA==
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716823214; l=1276;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=j8i6rPIxaLoMN9Ud6/vTWt11Mmg5pOxCMWSuFPY9J38=;
 b=UGbJxCz+LFACCSr4m4Uwl7rRZDZP+jxcQuRug+EDFL82OqyOBz2zwLTWD7ZBLoIFb4Gh2BvQf
 3E9AWCdCqKgDVvetqcrRUBLITbjYwV3WpN8WnbP7pFa5No3vdGurBMl
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds fixes for ad7173 driver that were originally
sent along AD411x series. To ensure that they are included in this
current rc cycle they are sent in a separate series with the Fixes tag.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
Changes in v2:
iio: adc: ad7173: Fix sampling frequency setting
-Patch created
iio: adc: ad7173: Clear append status bit
-Patch created
iio: adc: ad7173: Remove index from temp channel
iio: adc: ad7173: Add ad7173_device_info names
iio: adc: ad7173: fix buffers enablement for ad7176-2
-No changes

- Link to v1: https://lore.kernel.org/r/20240521-ad7173-fixes-v1-0-8161cc7f3ad1@analog.com

---
Dumitru Ceclan (5):
      iio: adc: ad7173: fix buffers enablement for ad7176-2
      iio: adc: ad7173: Add ad7173_device_info names
      iio: adc: ad7173: Remove index from temp channel
      iio: adc: ad7173: Clear append status bit
      iio: adc: ad7173: Fix sampling frequency setting

 drivers/iio/adc/ad7173.c | 35 +++++++++++++++++++----------------
 1 file changed, 19 insertions(+), 16 deletions(-)
---
base-commit: 5ab61121a34759eb2418977f0b3589b7edc57776
change-id: 20240521-ad7173-fixes-4e2e5a061ef2

Best regards,
-- 
Dumitru Ceclan <dumitru.ceclan@analog.com>

