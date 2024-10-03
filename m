From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 03 Oct 2024 15:38:22 +0200
Subject: [PATCH v2 1/3] MAINTAINERS: iio: migrate invensense email address
 to tdk domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241003-invn-maintainers-email-update-v2-1-ca5a4928eb22@tdk.com>
References: <20241003-invn-maintainers-email-update-v2-0-ca5a4928eb22@tdk.com>
In-Reply-To: <20241003-invn-maintainers-email-update-v2-0-ca5a4928eb22@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727962711; l=777;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=ijoFTmmkNW8P16NGl76tKyJtKzPzqes0lHYpjdQZKIk=;
 b=r534PF7HP2e6DfhgrBieLkacgWutAm0Miz14Iw25HR0aEssVw9MGicFlAsYaGM2s8wg9ZTavH
 b8KtdVsM6pmCQ1/P7myCun9E/Ka8Frj54/rdpX3jZJNcDBiQYRNYGGD
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

InvenSense is part of TDK group. Update email address to use the
TDK domain.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
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
2.46.2

