From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v2 0/2] iio: humditiy: hdc3020: fix units
Date: Mon, 01 Sep 2025 19:51:57 +0200
Message-Id: <20250901-hdc3020-units-fix-v2-0-082038a15917@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD3dtWgC/22NwQrCMBBEf6Xs2cgmIVo9+R/SQ7NZzYK2ktSil
 Py7seDN0/AG5s0CmZNwhmOzQOJZsoxDBbNpgGI/XFlJqAwGjcPWoIqBLNZ8DjJldZGXOmgO3rd
 EAfdQd4/EtV6d565ylDyN6b1ezPrb/mz6j23WCtWu9+jJOkuOTzdhHzmlLY136EopH19pgTe1A
 AAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756749134; l=1003;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=b7XeZ+yEoGgw2FiGDgxL+MvBGZvfBENVNCCoMU6n2Y4=;
 b=on697vJOMkKbcrDcOkYR+jTCEAaR3wXJJy0eKOKDuUHi4IYHL0ItLVdBGojnBoDwaTOqiYzXO
 +VkMYRzL02+Ds9cYv/PhsvzvfoAKp2RiclKK7UUAwMelWxZL5APREQo
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix units to milli degree celsius and milli percent for temperature
respectively relative humidity measurements and thresholds.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Added explanation what is wrong at the moment into commit msg
- Added define HDC3020_THRESH_FRACTION and comment at the beginning of the
  code.
- Use MILLI for instead of hardcoded 1000.
- Link to v1: https://lore.kernel.org/r/20250821-hdc3020-units-fix-v1-0-6ab0bc353c5e@liebherr.com

---
Dimitri Fedrau (2):
      iio: humditiy: hdc3020: fix units for temperature and humidity measurement
      iio: humditiy: hdc3020: fix units for thresholds and hysteresis

 drivers/iio/humidity/hdc3020.c | 73 +++++++++++++++++++++++++-----------------
 1 file changed, 43 insertions(+), 30 deletions(-)
---
base-commit: 43c0f6456f801181a80b73d95def0e0fd134e1cc
change-id: 20250820-hdc3020-units-fix-91edbb8ccd07

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

