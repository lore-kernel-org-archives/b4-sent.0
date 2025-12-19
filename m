From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/2] iio: adc: adi-axi-adc: Minor cleanups
Date: Fri, 19 Dec 2025 15:40:37 +0000
Message-Id: <20251219-iio-axi-adc-minor-change-v2-0-9d8e7270d19a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPVxRWkC/3WNwQ6CMBBEf4Xs2TXtSpF48j8Mh9oW2ERa0hqCI
 f13K9GjxzeZebNBcpFdgku1QXQLJw6+AB0qMKP2g0O2hYEEKUnihMwB9cqorcGJfYj47fXUSnM
 WJFrXQpnP0fW87upbV3jk9AzxtT8t8pP+pPV/6SJRINm6lrYx6t6oq/b6EYajCRN0Oec3hJUhH
 cEAAAA=
X-Change-ID: 20251203-iio-axi-adc-minor-change-f281c70208e8
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766158839; l=1067;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ov2yq43gUNo/inTJOGNOxiikI1eeNqjNvjRwoEmE+qk=;
 b=cFP2KEtGJZBSddQ4YMK1saKc90sTZ/oEfHbcoxF16vZ3sZMXUMNiMIo9JfHjv/Iy/sa2JQQ9F
 qGV6tviaV+hBehabBbT5QjqgInkAnxYYNoUr+yVOAagiN5519yn3nz+
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small series to use dev_err_probe() and turn dev_info() into dev_dbg().
It also simplifies axi_adc_create_platform_device() and makes it
consistent with what we have in the adi-axi-dac driver.

(I'm aware that the dev_err_probe() patch is not consistent with the
series on the axi-dac. I plan to also remove the braces in there as
David suggested).

I ended up dropping the patch that turned dev_info -> dev_dbg()

---
Changes in v2:
- Patch 1
   * Added helper struct device variable as suggested by Andy.
- Link to v1: https://lore.kernel.org/r/20251204-iio-axi-adc-minor-change-v1-0-2d441d6c5b65@analog.com

---
Nuno Sá (2):
      iio: adc: adi-axi-adc: Make use of dev_err_probe()
      iio: adc: adi-axi-adc: Slightly simplify axi_adc_create_platform_device()

 drivers/iio/adc/adi-axi-adc.c | 62 ++++++++++++++++++-------------------------
 1 file changed, 26 insertions(+), 36 deletions(-)
---
base-commit: f9e05791642810a0cf6237d39fafd6fec5e0b4bb
change-id: 20251203-iio-axi-adc-minor-change-f281c70208e8
--

Thanks!
- Nuno Sá

