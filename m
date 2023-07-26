From: Jon Mason <jon.mason@arm.com>
Date: Wed, 26 Jul 2023 08:01:34 -0400
Subject: [PATCH] arm-bsp/corstone1000: update u-boot preferred version
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230726-master-next-v1-1-cd4758222729@arm.com>
X-B4-Tracking: v=1; b=H4sIAB0LwWQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDcyMz3dzE4pLUIt281IoSXbNUcyNTyyQjc1MTQyWgjoKi1LTMCrBp0bG
 1tQBV992uXQAAAA==
To: meta-arm@lists.yoctoproject.org
Cc: Jon Mason <jon.mason@arm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1024; i=jon.mason@arm.com;
 h=from:subject:message-id; bh=sQE0DuhcCmT8Is/m+0RQlkke4os2pbu4QWdetsfVc2o=;
 b=owEBbQKS/ZANAwAKAW5mS6x6i9IjAcsmYgBkwQsszsrLxz+xD2/ZkpPM9DAWKmpTA9UidU9bD
 /svpvBpVgSJAjMEAAEKAB0WIQSgT1v1zdTYnFf3yapuZkuseovSIwUCZMELLAAKCRBuZkuseovS
 I+dxD/9EhgixHNEnlRSuBqqyLX2qVnDsxUJrUUZctSwrsR3Zr3jAk4wRpVzyhg63dVyKuxRmBxt
 UXthDDq+TkfoW6wvoj6sSeeuWIAYIfTc9FdvRLZbthDNkXnKKidXOKj1MYWGk8wB5ZM4s4k3tl/
 Z6Tf4sbVODDmYtZmPbIl9SGBQYxFMywYwowIrSifLIOKZVrqwSKF2jNQApfhYshVWNSM+8LhkO8
 98mnUPaUBYPcXdVFgtFBccRvSCwTlCPamc1fklfnmtTwbfvzZM+isBHURknRAjU+TPN7DZQONJG
 YFB7jb51/duwZvlRPoTzWTgATRFYDOLypsxYOpy7jCyx9+4RQ9JhGumNRdDYwjh2JlLS2rn9Upd
 shQTLAb8AYFj2dLx8cFmqBgaqjqt2vnGIQliY82B3KTJtoXTgkpaaGJuApjOcA6OH39khm3AwHE
 MM7tpFO1nZGr82aphY3qKViMWO9aK8eLQOEHYDPHNpzuohc2RSb8C+qSu18/OMTlWeYji44HZow
 m+Hx5EwHqFjyp+TqFPFgQVokVkdfv/faGZz+r2Tjt0IGnw8H0UpHfIi8kr+IVf/XvWWSBIpNy9p
 q8lXqxOMAEfW+P3FFSc2Z73iX7XtD7hTT+1GOp4/bb6DpwyM/WfZJ1/AqAL+kPEi5WHvh/9URyh
 neId8d7Jv3wAMrg==
X-Developer-Key: i=jon.mason@arm.com; a=openpgp;
 fpr=A04F5BF5CDD4D89C57F7C9AA6E664BAC7A8BD223
X-Endpoint-Received: by B4 Relay for jon.mason@arm.com/default with auth_id=58
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The upstream u-boot recipe did a minor version update, which is causing
a "preferred version not available" warning.  Add a '%' to resolve this
issue.

Signed-off-by: Jon Mason <jon.mason@arm.com>
---
 meta-arm-bsp/conf/machine/include/corstone1000.inc | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/meta-arm-bsp/conf/machine/include/corstone1000.inc b/meta-arm-bsp/conf/machine/include/corstone1000.inc
index da668c95218d..aeb1411ab992 100644
--- a/meta-arm-bsp/conf/machine/include/corstone1000.inc
+++ b/meta-arm-bsp/conf/machine/include/corstone1000.inc
@@ -22,7 +22,7 @@ TFM_SIGN_PRIVATE_KEY = "${libdir}/tfm-scripts/root-RSA-3072_1.pem"
 RE_IMAGE_OFFSET = "0x1000"
 
 # u-boot
-PREFERRED_VERSION_u-boot ?= "2023.07"
+PREFERRED_VERSION_u-boot ?= "2023.07%"
 EXTRA_IMAGEDEPENDS += "u-boot"
 
 UBOOT_CONFIG ??= "EFI"

---
base-commit: cfcc8a4d13c26793ecab2d8da9274eb98b8cb4ce
change-id: 20230726-master-next-6e7259b27541

Best regards,
-- 
Jon Mason <jon.mason@arm.com>

