From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 12 Feb 2024 10:07:05 +0100
Subject: [PATCH] iio: core: make use of DIV_ROUND_CLOSEST_ULL()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240212-iio-improve-define-dont-build-v1-1-875883bb9565@analog.com>
X-B4-Tracking: v=1; b=H4sIALjfyWUC/x2MwQqDMBAFf0X23IU1qLT9ldJDazbtgzaRRIMg/
 ruLp2FgmI2KZmihe7NR1oqCFE3aS0Pj9xU/yvDm5MR14lrHQGL8p5yqsteAaEhx5veCn+dRws0
 HkSFce7LHlC1Zz//jue8Hr4+lwG8AAAA=
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707728827; l=2450;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=X35iqJ6K0K5h9XuwhHfccmLQcWPxcL0Z/bKnPGFfk3Q=;
 b=Lao/omFK+SboBcAVxAka5TRnnXTewPknOU8xDcscluVsKtB+67cxFE+204IZEJ6rMu/A/bLNo
 xOgp9q9Fb36C4XGpoVKprrJUKvC2HUIG4GSBbYRzXkYUhK9BV/B/kKD
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of open code DIV_ROUND_CLOSEST_ULL(), let's use it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
1) For some reason IIO_G_TO_M_S_2() does do not a closest division. Not
   sure if there's a reason for it or just something that was forgotten.
   Anyways, I left it as it was before.

2) This conversion could actually be required. In some experiments with
   it (in a series I'm working on), I actually realized with
   IIO_RAD_TO_DEGREE() that  we could have a 64bit division in 32bits
   archs. I'm still not treating it as a fix as no one ever complained.
   Jonathan, let me know if you want me to send a follow up email (or v2)
   with a proper tag.
---
 include/linux/iio/iio.h | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/include/linux/iio/iio.h b/include/linux/iio/iio.h
index e370a7bb3300..3ebf9fe97f0e 100644
--- a/include/linux/iio/iio.h
+++ b/include/linux/iio/iio.h
@@ -10,6 +10,7 @@
 #include <linux/device.h>
 #include <linux/cdev.h>
 #include <linux/cleanup.h>
+#include <linux/math.h>
 #include <linux/slab.h>
 #include <linux/iio/types.h>
 /* IIO TODO LIST */
@@ -799,8 +800,8 @@ int iio_str_to_fixpoint(const char *str, int fract_mult, int *integer,
  *
  * Returns the given value converted from degree to rad
  */
-#define IIO_DEGREE_TO_RAD(deg) (((deg) * 314159ULL + 9000000ULL) / 18000000ULL)
-
+#define IIO_DEGREE_TO_RAD(deg) \
+	DIV_ROUND_CLOSEST_ULL((deg) * 314159ULL, 18000000)
 /**
  * IIO_RAD_TO_DEGREE() - Convert rad to degree
  * @rad: A value in rad
@@ -808,7 +809,7 @@ int iio_str_to_fixpoint(const char *str, int fract_mult, int *integer,
  * Returns the given value converted from rad to degree
  */
 #define IIO_RAD_TO_DEGREE(rad) \
-	(((rad) * 18000000ULL + 314159ULL / 2) / 314159ULL)
+	DIV_ROUND_CLOSEST_ULL((rad) * 18000000ULL + 314159)
 
 /**
  * IIO_G_TO_M_S_2() - Convert g to meter / second**2
@@ -824,6 +825,6 @@ int iio_str_to_fixpoint(const char *str, int fract_mult, int *integer,
  *
  * Returns the given value converted from meter / second**2 to g
  */
-#define IIO_M_S_2_TO_G(ms2) (((ms2) * 100000ULL + 980665ULL / 2) / 980665ULL)
+#define IIO_M_S_2_TO_G(ms2) DIV_ROUND_CLOSEST_ULL((ms2) * 100000ULL, 980665)
 
 #endif /* _INDUSTRIAL_IO_H_ */

---
base-commit: bd2f1ed8873d4bbb2798151bbe28c86565251cfb
change-id: 20240212-iio-improve-define-dont-build-c0f9df006f85
--

Thanks!
- Nuno Sá

