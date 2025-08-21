From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH 0/2] iio: humditiy: hdc3020: fix units
Date: Thu, 21 Aug 2025 17:23:53 +0200
Message-Id: <20250821-hdc3020-units-fix-v1-0-6ab0bc353c5e@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAk6p2gC/x2MSwqAMAwFryJZW4gV8XMVcWGbqNlUaVWE4t0Nr
 oYZeC9D4iicYCgyRL4lyR5UqrIAv81hZSOkDhZtg51Fs5GvUXkFOZNZ5DF9xeRc5z1hC7o7Imv
 +P8fpfT/+WaSRYwAAAA==
X-Change-ID: 20250820-hdc3020-units-fix-91edbb8ccd07
To: Javier Carrasco <javier.carrasco.cruz@gmail.com>, 
 Li peiyu <579lpy@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Chris Lesiak <chris.lesiak@licorbio.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755789852; l=687;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=j5HMtzj02bE7jOzvhivWK4JuewQ6uKDmB/pcYi4qcJA=;
 b=4Rb/szGb6OxfFXpOylVFSLvZkCNBkkMeNtlU/nhO4B5VOB47d6xmHgFUAKQuKsTNEtCG+SGEK
 IERaq0i0Z1VDe1L7+XpbRuyp//h/PfbXN/lnxSipa6yKDXJ9vqPrnua
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix units to milli degree celsius and milli percent for temperature
respectively relative humidity measurements and thresholds.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      iio: humditiy: hdc3020: fix units for temperature and humidity measurement
      iio: humditiy: hdc3020: fix units for thresholds and hysteresis

 drivers/iio/humidity/hdc3020.c | 46 +++++++++++++++++++++---------------------
 1 file changed, 23 insertions(+), 23 deletions(-)
---
base-commit: 43c0f6456f801181a80b73d95def0e0fd134e1cc
change-id: 20250820-hdc3020-units-fix-91edbb8ccd07

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

