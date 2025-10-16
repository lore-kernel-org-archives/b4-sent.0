From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v4 0/2] iio: humditiy: hdc3020: fix units
Date: Thu, 16 Oct 2025 07:20:37 +0200
Message-Id: <20251016-hdc3020-units-fix-v4-0-2d9e9f33c7b1@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKWA8GgC/23OwQrCMAwG4FcZPVtJWuc6T76HeFjbzBZ0k3YWZ
 ezd7QYqyE7h/yFfMrJIwVNkh2JkgZKPvu9y2G0KZlzTXYh7mzMTIEpQArizRkKej84Pkbf+yWs
 kq7UyxkLF8t49UK4X83TO2fk49OG1nEg4tx8NV7SEHPi+0aCNLKUp6Xj1pB2FsDX9jc1gEj+kh
 lVEZGR+V6oGyxqrFUR+EQSUa4jMiBbYNloKrZT4Q6ZpegNV9LjfPwEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760592043; l=1749;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=ITUgx3N03EK9CFNyirfZfXh7cU+zPoME+aIpuLj0Acs=;
 b=N09qwM+v+PNKWl7FPdJLocOTs2GKdT2AnWfWVq7ZXDUesAjWmHCUBD49XCLz9D0mbegssSRKw
 07ubwFeDLEwCcuMDwWTcJK109d0CQko9JBCPprFcexngdn4EXnnQN0L
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix units to milli degree celsius and milli percent for temperature
respectively relative humidity measurements and thresholds.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v4:
- Add explicit formula into comments of hdc3020_thresh_get_temp and
  hdc3020_thresh_get_hum
- Add explicit division by 5 into calculations in hdc3020_thresh_get_temp
  and hdc3020_thresh_get_hum
- Link to v3: https://lore.kernel.org/r/20251013-hdc3020-units-fix-v3-0-b21fab32b882@liebherr.com

Changes in v3:
- Fix verbose comment for define HDC3020_THRESH_FRACTION (Javier)
- Embed prescale into define HDC3020_THRESH_FRACTION to make the division
  by 5 calculation in threshold calculations explicit. (Andy)
- Add resulting units into comments again in hdc3020_thresh_get_temp and
  hdc3020_thresh_get_hum (Andy)
- Link to v2: https://lore.kernel.org/r/20250901-hdc3020-units-fix-v2-0-082038a15917@liebherr.com

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
base-commit: 875e7d357a7f2e77a7f3fc4759d0aa0872c33027
change-id: 20250820-hdc3020-units-fix-91edbb8ccd07

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

