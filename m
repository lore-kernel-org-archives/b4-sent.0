From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/3] iio: adc: adi-axi-adc: Minor cleanups
Date: Thu, 04 Dec 2025 15:24:16 +0000
Message-Id: <20251204-iio-axi-adc-minor-change-v1-0-2d441d6c5b65@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKCnMWkC/y2MQQqEMBAEvyJzdiAZWQx+RTyEONntg4kkIIL4d
 4PssaCqLqpaoJWm7qKiBypyamD7jsLPp68y1sYkRj5WzMBAZn+C/Rp4Q8qF/14UZ8NoxDh11PK
 9aMT5ruflvh9WSXd9agAAAA==
X-Change-ID: 20251203-iio-axi-adc-minor-change-f281c70208e8
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764861858; l=852;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=F10jaYF8Tg9Y+5FGZpu9v2Se6DGRDlrFpYFnzeV2Vo8=;
 b=PFNiArMfFnEyixMd+XaWpTpgJpQ37YUj0Do98L0cish9NyiWBgMu/OQywEQagLUeUzcMF3WMy
 Et+h0DYjxfuDVl+D1J4wwtzIx73Hql1NQks0bzSc/C8nTAbgGS/ROe+
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

---
Nuno Sá (3):
      iio: adc: adi-axi-adc: Make use of dev_err_probe()
      iio: adc: adi-axi-adc: Turn dev_info() into dev_dbg()
      iio: adc: adi-axi-adc: Slightly simplify axi_adc_create_platform_device()

 drivers/iio/adc/adi-axi-adc.c | 36 ++++++++++++++----------------------
 1 file changed, 14 insertions(+), 22 deletions(-)
---
base-commit: f9e05791642810a0cf6237d39fafd6fec5e0b4bb
change-id: 20251203-iio-axi-adc-minor-change-f281c70208e8
--

Thanks!
- Nuno Sá

