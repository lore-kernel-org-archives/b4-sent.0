From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 05 Nov 2026 18:11:45 +0530
Subject: [PATCH 3/5] iio: magnetometer: hid-sensor-magn-3d: drop redundant
 probe error messages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-19-oct-hid-iio-unified-print-framework-v1-3-0b360d9552d9@gmail.com>
References: <20261105-19-oct-hid-iio-unified-print-framework-v1-0-0b360d9552d9@gmail.com>
In-Reply-To: <20261105-19-oct-hid-iio-unified-print-framework-v1-0-0b360d9552d9@gmail.com>
To: Jiri Kosina <jikos@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-input@vger.kernel.org, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793882514; l=2291;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=qC1Lxu8F4R235soajdiBHvZUF8Jt4qICpTs8qOVi7Kc=;
 b=gGnLOr9gNzaTqu+nS4pU1eTMBNOqk8sucDT3fSqEsyOfisDSBCb80VF69NzBH5M6xqaANdRIp
 vGdxa6uAMMxCoCtg+uoM4byGnbMH9w3ubMNWCMNTfdgr3wa+4ocR8zn
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The probe path emits error messages for conditions where the failure is
either already conveyed by the returned error code or can be identified
from the existing debug messages in the magn_3d_parse_report().

Remove the redundant error messages to reduce log noise and simplify the
error handling code.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/magnetometer/hid-sensor-magn-3d.c | 20 ++++----------------
 1 file changed, 4 insertions(+), 16 deletions(-)

diff --git a/drivers/iio/magnetometer/hid-sensor-magn-3d.c b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
index 911b15a5175d..fb9a561706a8 100644
--- a/drivers/iio/magnetometer/hid-sensor-magn-3d.c
+++ b/drivers/iio/magnetometer/hid-sensor-magn-3d.c
@@ -356,11 +356,8 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 			attr_count++;
 	}
 
-	if (attr_count <= 0) {
-		dev_err(&pdev->dev,
-			"failed to find any supported usage attributes in report\n");
+	if (attr_count <= 0)
 		return  -EINVAL;
-	}
 
 	dev_dbg(&pdev->dev, "magn_3d Found %d usage attributes\n", attr_count);
 	dev_dbg(&pdev->dev, "magn_3d X: %x:%x Y: %x:%x Z: %x:%x\n",
@@ -373,21 +370,15 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 	_channels = devm_kcalloc(&pdev->dev, attr_count,
 				 sizeof(struct iio_chan_spec),
 				 GFP_KERNEL);
-	if (!_channels) {
-		dev_err(&pdev->dev,
-			"failed to allocate space for iio channels\n");
+	if (!_channels)
 		return -ENOMEM;
-	}
 
 	/* attr_count include timestamp channel, and the iio_vals should be aligned to 8byte */
 	st->iio_vals = devm_kcalloc(&pdev->dev,
 				    ((attr_count + 1) % 2 + (attr_count + 1) / 2) * 2,
 				    sizeof(u32), GFP_KERNEL);
-	if (!st->iio_vals) {
-		dev_err(&pdev->dev,
-			"failed to allocate space for iio values array\n");
+	if (!st->iio_vals)
 		return -ENOMEM;
-	}
 
 	for (i = 0, *chan_count = 0;
 	i < MAGN_3D_CHANNEL_MAX && *chan_count < attr_count;
@@ -411,11 +402,8 @@ static int magn_3d_parse_report(struct platform_device *pdev,
 		}
 	}
 
-	if (*chan_count <= 0) {
-		dev_err(&pdev->dev,
-			"failed to find any magnetic channels setup\n");
+	if (*chan_count <= 0)
 		return -EINVAL;
-	}
 
 	*channels = _channels;
 

-- 
2.34.1

