From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 19 Jan 2026 14:36:55 +0000
Subject: [PATCH 1/7] MAINTAINERS: Add missing maintainer entry for AD8366
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-iio-ad8366-update-v1-1-8044e23e964a@analog.com>
References: <20260119-iio-ad8366-update-v1-0-8044e23e964a@analog.com>
In-Reply-To: <20260119-iio-ad8366-update-v1-0-8044e23e964a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768833448; l=890;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=rob+NAZkHfCiMJf8OmO/3rqHiaqTB4rC3m2DW61I/hw=;
 b=6hPObne3IZwi5e5qhPoH2SIEVRDnrUBNyf3hrhYjWzrS+d76rkW3+SJ6J67va/4rz/A4OkX+4
 T2Vqevb6abRBwDg1690Dxrw5HmSeU6FpjqSfmY5/Jf2fCA8hJJrv6/Q
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add maintainers entry for drivers/iio/amplifiers/ad8366.c

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4dd9f758a871..9c8e83470464 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1583,6 +1583,14 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad7780.yaml
 F:	drivers/iio/adc/ad7780.c
 
+ANALOG DEVICES INC AD8366 DRIVER
+M:	Michael Hennerich <Michael.Hennerich@analog.com>
+M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	drivers/iio/amplifiers/ad8366.c
+
 ANALOG DEVICES INC AD9467 DRIVER
 M:	Michael Hennerich <Michael.Hennerich@analog.com>
 M:	Nuno Sa <nuno.sa@analog.com>

-- 
2.43.0

