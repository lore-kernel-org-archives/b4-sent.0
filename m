From: Petar Stoykov <pd.pstoykov@gmail.com>
Date: Thu, 25 Jul 2024 17:37:29 +0200
Subject: [PATCH v4 3/3] MAINTAINERS: Add Sensirion SDP500
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240725-mainline_sdp500-v4-3-ea2f5b189958@gmail.com>
References: <20240725-mainline_sdp500-v4-0-ea2f5b189958@gmail.com>
In-Reply-To: <20240725-mainline_sdp500-v4-0-ea2f5b189958@gmail.com>
To: linux-iio@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Petar Stoykov <pd.pstoykov@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721921965; l=814;
 i=pd.pstoykov@gmail.com; s=20240702; h=from:subject:message-id;
 bh=FLAhfhEw/kb4vXK4acn1ghnoUaHh0QtVdAQd8Si6n7c=;
 b=7xkmAXxsLkwjB25+M1dMumspAWOT0w4Bp+r4IJoF6imXvAJz+2ITqfoT4n42VhNPx2dQUiQwi
 iwOwy3PALbWC5KwMQKLo70ieNwZQJU1dOiJgLNFQZ4qijpAd4+CJGBm
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
index 40c754b4c39c..fae39d65d676 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19533,6 +19533,12 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/chemical/sensirion,scd4x.yaml
 F:	drivers/iio/chemical/scd4x.c
 
+SENSIRION SDP500 DIFFERENTIAL PRESSURE SENSOR DRIVER
+M:	Petar Stoykov <petar.stoykov@prodrive-technologies.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/iio/pressure/sensirion,sdp500.yaml
+F:	drivers/iio/pressure/sdp500.c
+
 SENSIRION SGP40 GAS SENSOR DRIVER
 M:	Andreas Klinger <ak@it-klinger.de>
 S:	Maintained

-- 
2.39.2

