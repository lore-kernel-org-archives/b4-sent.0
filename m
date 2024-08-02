From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 02 Aug 2024 16:27:02 +0200
Subject: [PATCH v2 4/8] iio: adc: adi-axi-adc: support modified prbs23
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-dev-iio-backend-add-debugfs-v2-4-4cb62852f0d0@analog.com>
References: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
In-Reply-To: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722608829; l=882;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=EQ5g4pJjEx9y5MLKCN3xwUb/Fi6/zxslXRaMN+MVLzQ=;
 b=j0mb6dHbN5EOar75CK9yfPLWGQhPtPzcVEPFb+edAGwsr3a3LM0k3/a1/hr2/W4xiFy0bCIcA
 PI9ucU1pRjvBN9NHhZRiz0z2GGxUFJM1ZxUhlGbpicYoFpeCtou8JU3
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for configuring the prbs23 sequence.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 0a9d7433da30..f4cdfcca865d 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -199,6 +199,10 @@ static int axi_adc_test_pattern_set(struct iio_backend *back,
 		return regmap_update_bits(st->regmap, ADI_AXI_ADC_REG_CHAN_CTRL_3(chan),
 					  ADI_AXI_ADC_CHAN_PN_SEL_MASK,
 					  FIELD_PREP(ADI_AXI_ADC_CHAN_PN_SEL_MASK, 0));
+	case IIO_BACKEND_ADI_PRBS_23A:
+		return regmap_update_bits(st->regmap, ADI_AXI_ADC_REG_CHAN_CTRL_3(chan),
+					  ADI_AXI_ADC_CHAN_PN_SEL_MASK,
+					  FIELD_PREP(ADI_AXI_ADC_CHAN_PN_SEL_MASK, 1));
 	default:
 		return -EINVAL;
 	}

-- 
2.45.2

