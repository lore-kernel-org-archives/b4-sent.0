From: Petar Stoykov <pd.pstoykov@gmail.com>
Date: Tue, 02 Jul 2024 16:59:10 +0200
Subject: [PATCH v3 3/3] MAINTAINERS: Add Sensirion SDP500
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-mainline_sdp500-v3-3-0902047b3eee@gmail.com>
References: <20240702-mainline_sdp500-v3-0-0902047b3eee@gmail.com>
In-Reply-To: <20240702-mainline_sdp500-v3-0-0902047b3eee@gmail.com>
To: linux-iio@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Petar Stoykov <pd.pstoykov@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719932376; l=804;
 i=pd.pstoykov@gmail.com; s=20240702; h=from:subject:message-id;
 bh=++KMBJJdkAu/mRC0gJaUp/zFLhaTtFAt27IBrDli1ZM=;
 b=NSO1Rjq0Zm5akuTrH+ez/GsVoiUzK0DPfANPoSj2ZB/R4e8LZWMF3Wnrtd35y6onxYIxR+E30
 7QnG0lpDk6tAz9weSIbDYuYHtZs6RF2fFk8C9bKWg8CyRr8WCf4wAUW
X-Developer-Key: i=pd.pstoykov@gmail.com; a=ed25519;
 pk=oxcGqcVV5O6wqlTh+39SbOwfbpD763i5x4TavUAHiCg=
X-Endpoint-Received: by B4 Relay for pd.pstoykov@gmail.com/20240702 with auth_id=179
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself as a maintainer for Sensirion SDP500 pressure sensor driver

Signed-off-by: Petar Stoykov <pd.pstoykov@gmail.com>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 40c754b4c39c..65f9479ac343 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19533,6 +19533,12 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/chemical/sensirion,scd4x.yaml
 F:	drivers/iio/chemical/scd4x.c
 
+SENSIRION SDP500 DIFFERENTIAL PRESSURE SENSOR DRIVER
+M:	Petar Stoykov <petar.stoykov@prodrive-technologies.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/iio/pressure/sdp500.yaml
+F:	drivers/iio/pressure/sdp500.c
+
 SENSIRION SGP40 GAS SENSOR DRIVER
 M:	Andreas Klinger <ak@it-klinger.de>
 S:	Maintained

-- 
2.39.2

