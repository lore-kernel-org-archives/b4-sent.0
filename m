From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 03 Oct 2024 09:37:45 +0200
Subject: [PATCH 1/3] MAINTAINERS: iio: migrate invensense email address to
 tdk domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241003-invn-maintainers-email-update-v1-1-7e4062ad68cf@tdk.com>
References: <20241003-invn-maintainers-email-update-v1-0-7e4062ad68cf@tdk.com>
In-Reply-To: <20241003-invn-maintainers-email-update-v1-0-7e4062ad68cf@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727941073; l=703;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=bnLpFpdGSdAAgRlcBRyqc8VlLbTmu7ekBGszqaJYuJI=;
 b=6THKOwF3SO7EIqHKot5HNqh+342ZX40WpOOahQnVngw76Lmjabv6QaRApqY+o5lO/JQfOKmM/
 2IEKKHjOe81CKN+0/r2Nx8A3nzbdN8kAYGwecFAtH83yZhkoGHPmxLi
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

InvenSense is part of TDK group. Update email address to use the
TDK domain.
---
 MAINTAINERS | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index bcdf43f37660403f3adb11884f1c58f64bc32840..b6b252b991a514e225df309485c708c2af547f57 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11898,7 +11898,7 @@ F:	Documentation/devicetree/bindings/media/i2c/isil,isl79987.yaml
 F:	drivers/media/i2c/isl7998x.c
 
 INVENSENSE ICM-426xx IMU DRIVER
-M:	Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
+M:	Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
 L:	linux-iio@vger.kernel.org
 S:	Maintained
 W:	https://invensense.tdk.com/

-- 
2.34.1

