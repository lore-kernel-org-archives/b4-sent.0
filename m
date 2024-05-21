From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Subject: [PATCH 0/3] AD7173 fixes
Date: Tue, 21 May 2024 11:45:38 +0300
Message-Id: <20240521-ad7173-fixes-v1-0-8161cc7f3ad1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADJfTGYC/x3LQQqAIBBG4avErBN00oSuEi0kf2s2FgoRRHdPW
 n483kMVRVBp6h4quKTKkRtM39G6h7xBSWwm1my1Y6NC9MYPKsmNqiwYLujRIDG15Sz4Qzvm5X0
 /Vkpz3V4AAAA=
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716281184; l=743;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=SiXMPzFyIkTEwRXRmeckMbEvLhH98lpRv9fx8PUHfMk=;
 b=mbQ9Sc9j2q9NvpEcKkqyc2ZV88kcFbtvJ4v0Mzpc8nUEUSH8X9JiETPM2gregjT5H5N0Okut7
 ernOZyzGcYOBfoCpUAQEcIxKX+Xyi081We6W7WiBJEWO+tkb/uRldut
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds fixes for ad7173 driver that were originally
sent along AD411x series. To ensure that they are included in this
current rc cycle they are sent in a separate series with the Fixes tag.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
Dumitru Ceclan (3):
      iio: adc: ad7173: fix buffers enablement for ad7176-2
      iio: adc: ad7173: Add ad7173_device_info names
      iio: adc: ad7173: Remove index from temp channel

 drivers/iio/adc/ad7173.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)
---
base-commit: 5ab61121a34759eb2418977f0b3589b7edc57776
change-id: 20240521-ad7173-fixes-4e2e5a061ef2

Best regards,
-- 
Dumitru Ceclan <dumitru.ceclan@analog.com>

