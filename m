From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Subject: [PATCH v3 0/5] AD7173 fixes
Date: Thu, 30 May 2024 15:07:48 +0300
Message-Id: <20240530-ad7173-fixes-v3-0-b85f33079e18@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABRsWGYC/3XMQQ7CIBCF4as0rMUwQwvGlfcwLigMLYkWA4Zom
 t5d2pWauHwz+f6ZZUqBMjs2M0tUQg5xqkPuGmZHMw3Eg6ubocBWdAjcOA1ach+elHlLSJ0RCsg
 jq+SeaHtUcb7UPYb8iOm11Qus1z+hAlzwAyiwVntpHJzMZK5x2Nt4Y2up4KfWPxpX3QnolTKuB
 /+ll2V5A1WTe6rnAAAA
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717070881; l=1703;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=a2Nv0nM1QFck0HLI7Wyar8ElOhaHIMfdrqsrvPCL3Y4=;
 b=NRguLoiKT+O+Qi5WkKw/aEGTWSXghee5MxGlf4svNKtOkkARVnLaBpARyZ4N8u3gSKIlCiMvL
 vn22Ao8yR7/Aay0QuUOSZHt7+JXkYKOPFJJoB7ILLUyLOkQNKWSJOJf
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds fixes for ad7173 driver that were originally
sent along AD411x series. To ensure that they are included in this
current rc cycle they are sent in a separate series with the Fixes tag.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
Changes in v3:
iio: adc: ad7173: Fix sampling frequency setting
-Remove IIO_CHAN_INFO_SAMP_FREQ from the shared mask
iio: adc: ad7173: Clear append status bit
iio: adc: ad7173: Remove index from temp channel
iio: adc: ad7173: Add ad7173_device_info names
iio: adc: ad7173: fix buffers enablement for ad7176-2
-No changes

- Link to v2: https://lore.kernel.org/r/20240527-ad7173-fixes-v2-0-8501b66adb1f@analog.com

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

 drivers/iio/adc/ad7173.c | 37 +++++++++++++++++++------------------
 1 file changed, 19 insertions(+), 18 deletions(-)
---
base-commit: 5ab61121a34759eb2418977f0b3589b7edc57776
change-id: 20240521-ad7173-fixes-4e2e5a061ef2

Best regards,
-- 
Dumitru Ceclan <dumitru.ceclan@analog.com>

