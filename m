From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Mon, 09 Nov 2026 11:39:02 +0000
Subject: [PATCH 1/2] iio: light: adux1020: fix interrupt clear value on
 SMBus-only adapters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-adux1020-measure-fixes-v1-1-fe1ba63f28bc@gmail.com>
References: <20261109-adux1020-measure-fixes-v1-0-fe1ba63f28bc@gmail.com>
In-Reply-To: <20261109-adux1020-measure-fixes-v1-0-fe1ba63f28bc@gmail.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794224343; l=1379;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=r0ZSbO/Ld4MVFSPmXF2iaVAjnoCBKisOgRdgkZhMCRw=;
 b=Lv77MYIhtCIDIjnpPc9VCu9My+u0Qn91R1RGUysL3NaIsmiXtHiDCQ42UFSCBZ2Ncph52XTl0
 1EgtEa/iXfOC5Ef15NlRhdop9O8WTPmIbbIYcj7wNb3HZyOIXszNGUs
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

adux1020_measure() clears the mode interrupt by writing the inverted
interrupt enable mask to INT_STATUS. The mask is a u16, but integer
promotion makes ~0x00f0 evaluate to 0xffffff0f, which does not fit in
the 16-bit register.

On adapters supporting plain I2C, regmap formats the value with
put_unaligned_be16() and silently truncates it to 0xff0f. On adapters
that only support SMBus word transfers, regmap_smbus_word_write_swapped()
rejects values above 0xffff with -EINVAL, so every proximity read fails.

Mask the value to 16 bits so that SMBus-only adapters send the same
0xff0f that has always been written on plain I2C adapters.

Fixes: 356543545576 ("iio: light: Add support for ADUX1020 sensor")
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/iio/light/adux1020.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/light/adux1020.c b/drivers/iio/light/adux1020.c
index d4281b9754c3..cccd509dd18a 100644
--- a/drivers/iio/light/adux1020.c
+++ b/drivers/iio/light/adux1020.c
@@ -346,7 +346,7 @@ static int adux1020_measure(struct adux1020_data *data,
 
 	/* Clear mode interrupt */
 	ret = regmap_write(data->regmap, ADUX1020_REG_INT_STATUS,
-			   (~adux1020_modes[mode].int_en));
+			   ~adux1020_modes[mode].int_en & 0xffff);
 	if (ret < 0)
 		return ret;
 

-- 
2.56.0

