From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Mon, 09 Nov 2026 11:39:03 +0000
Subject: [PATCH 2/2] iio: light: adux1020: extract the FIFO byte count with
 FIELD_GET()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-adux1020-measure-fixes-v1-2-fe1ba63f28bc@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794224343; l=1221;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=XsuW70+va29sa1QD4DljbLTZAicup6mt3PPzvSsELWA=;
 b=MJsbFtOFSHMT74bZQ616PxNSEXPCHJ0tPpLBe58Yv6A/JDUNhapnFPjXmA4zGP4VgGD35jLQ6
 /sl6iNXwG4WCbOf62Lj+f2Tps8hrv5nlPmnrUKDfkshsGhbp2OFwCCo
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

adux1020_measure() masks INT_STATUS with ADUX1020_FIFO_STATUS_MASK but
does not shift the result down, so it compares 256 times the FIFO byte
count against the packet size. A count of 1 would thus be treated as a
complete 2-byte proximity packet.

This does not happen on a correctly working device, because the FIFO
only stores complete packets and the driver always reads complete
packets, so the count is always a multiple of the packet size. Still,
use FIELD_GET() so the comparison matches the datasheet's polling
procedure and does not depend on that.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/iio/light/adux1020.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/light/adux1020.c b/drivers/iio/light/adux1020.c
index cccd509dd18a..dd5230c6dceb 100644
--- a/drivers/iio/light/adux1020.c
+++ b/drivers/iio/light/adux1020.c
@@ -331,7 +331,7 @@ static int adux1020_measure(struct adux1020_data *data,
 		if (ret < 0)
 			return ret;
 
-		status &= ADUX1020_FIFO_STATUS_MASK;
+		status = FIELD_GET(ADUX1020_FIFO_STATUS_MASK, status);
 		if (status >= adux1020_modes[mode].bytes)
 			break;
 		msleep(20);

-- 
2.56.0

