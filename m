From: Sanjay Chitroda <sanjayembeddedse@gmail.com>
Date: Thu, 02 Jul 2026 21:48:03 +0530
Subject: [PATCH v2 6/6] iio: temperature: hid-sensor-temperature: use
 common device for devres
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260702-15-jun-hid-iio-alignment-v2-6-b87f01f5efbc@gmail.com>
References: <20260702-15-jun-hid-iio-alignment-v2-0-b87f01f5efbc@gmail.com>
In-Reply-To: <20260702-15-jun-hid-iio-alignment-v2-0-b87f01f5efbc@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-input@vger.kernel.org, Sanjay Chitroda <sanjayembeddedse@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783009082; l=1531;
 i=sanjayembeddedse@gmail.com; s=20260702; h=from:subject:message-id;
 bh=4701Zl6ga9a1z4yj3Yz9gyyh1nnaOn4C8ewcual1JXA=;
 b=jt3v7QdjWsfgAfapZwFm0C9YNA79+MuK2w12LOFbEHrlpVz05FnImDeiSt5LBiqmdG+XpONgq
 fVMLvt/ITxrAXnZwacib1+ey+TtLlS9hway7fYeVnhNzUgud03Pqout
X-Developer-Key: i=sanjayembeddedse@gmail.com; a=ed25519;
 pk=PcneEFtkmY+Ldl+KmOTpB/Q/HDsqko6Fb0/Z/5cuycI=
X-Endpoint-Received: by B4 Relay for sanjayembeddedse@gmail.com/20260702 with auth_id=848
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kmemdup() is used for memory that is logically tied to the HID
platform device, even though the driver binds into the IIO framework.

Using &indio_dev->dev for devres allocations works functionally, but it
results in two separate devres ownership trees—one for the HID
platform device (pdev) and another for the IIO device (indio_dev).

The devres framework is intended to have a single, well-defined parent
device. Since the memory originates from HID sensor probing and is not
IIO-specific, &pdev->dev is the correct and logical owner.

Switch to using the platform device for devm_kmemdup() so that all
resources are released deterministically and consistently.

Signed-off-by: Sanjay Chitroda <sanjayembeddedse@gmail.com>
---
 drivers/iio/temperature/hid-sensor-temperature.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/temperature/hid-sensor-temperature.c b/drivers/iio/temperature/hid-sensor-temperature.c
index 18da85e6c60e..6dfb606a53af 100644
--- a/drivers/iio/temperature/hid-sensor-temperature.c
+++ b/drivers/iio/temperature/hid-sensor-temperature.c
@@ -213,8 +213,8 @@ static int hid_temperature_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	temp_chans = devm_kmemdup(&indio_dev->dev, temperature_channels,
-				sizeof(temperature_channels), GFP_KERNEL);
+	temp_chans = devm_kmemdup(&pdev->dev, temperature_channels,
+				  sizeof(temperature_channels), GFP_KERNEL);
 	if (!temp_chans)
 		return -ENOMEM;
 

-- 
2.34.1

