From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/2] iio: dac: ltc2688: minor cleanups
Date: Tue, 23 Sep 2025 09:41:46 +0100
Message-Id: <20250923-dev-ltc2688-minor-v1-0-ef92c441dc42@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEpd0mgC/x3MQQqAIBBA0avIrBswI9GuEi0spxooCw0JorsnL
 d/i/wcSRaYEnXggUubERyioKwHT6sJCyL4YlFSttKpBTxm3a1LaGNw5HBGl04Zsq0dpDZTujDT
 z/T/74X0/UaN5KmMAAAA=
X-Change-ID: 20250923-dev-ltc2688-minor-0a68e956b098
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758616915; l=441;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=sl+i70X/edd/QDfpVdgYIN8i9Z9A4Daw02aKDix/xYs=;
 b=1faBrWwOjhbFNRihR+Fe5vHDqcTkEw78zzZiyhOQgBkmZx2hBTGGGLvKKU8/B9URc+qzr0mkd
 UkConcoKYsMDBA3Bb5BHJilHEnkmk5GU7UVj0gqfSss9qdCeKoQgcMr
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simple series to improve locking and mutex initialization.

---
Nuno Sá (2):
      iio: dac: ltc2688: make use of devm_mutex_init()
      iio: dac: ltc2688: use the auto lock API

 drivers/iio/dac/ltc2688.c | 28 +++++++++++++---------------
 1 file changed, 13 insertions(+), 15 deletions(-)
---
base-commit: 411e8b72c181e4f49352c12ced0fd8426eb683aa
change-id: 20250923-dev-ltc2688-minor-0a68e956b098
--

Thanks!
- Nuno Sá

