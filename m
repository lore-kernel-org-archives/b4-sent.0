From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 06 Aug 2024 15:10:39 +0200
Subject: [PATCH 1/2] MAINTAINERS: add entry for ad9467
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240806-dev-ad-debugfs-doc-v1-1-153b882a3f01@analog.com>
References: <20240806-dev-ad-debugfs-doc-v1-0-153b882a3f01@analog.com>
In-Reply-To: <20240806-dev-ad-debugfs-doc-v1-0-153b882a3f01@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722949842; l=910;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=0ISwLenbTtN0B41a+pby8UWaWMuEWdaKv5v9O1GxGtU=;
 b=okf3f9JUB/Ef6s9yeST9Y9jgl9t5QHFk85dbdtiOy69+nywBPFvGxXDcf2RCRo6708Tkk03Tw
 Wcy93qK/QPeCKBuKnx8OXD1+z1q1skXjw/eCwwQDcv1wKYg/1FFNDFg
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the maintainers for the IIO ad9467 high speed ADC.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 2708a9e9fc95..ff62a4c2ce9e 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1310,6 +1310,15 @@ W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/adc/adi,ad7780.yaml
 F:	drivers/iio/adc/ad7780.c
 
+ANALOG DEVICES INC AD9467 DRIVER
+M:	Michael Hennerich <Michael.Hennerich@analog.com>
+M:	Nuno Sa <nuno.sa@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Supported
+W:	https://ez.analog.com/linux-software-drivers
+F:	Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
+F:	drivers/iio/adc/ad9467.c
+
 ANALOG DEVICES INC AD9739a DRIVER
 M:	Nuno Sa <nuno.sa@analog.com>
 M:	Dragos Bogdan <dragos.bogdan@analog.com>

-- 
2.45.2

