From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 20:07:55 -0600
Subject: [PATCH 1/4] staging: octeon: add kernel-doc to ethernet-sgmii.c
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-phy-series-v2-v1-1-d7ab0b4b3f17@gmail.com>
References: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
In-Reply-To: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794103676; l=1244;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=pXGe9ISk/CZTC57vfsChGPvOtfOD2S1zoLUk/A+V/3Q=;
 b=GmCDf72LC2vn62S50waLjNM24nrJYRRazybn3P3HE6WGFhFyTvOqxcnpKSUG1nluksprY0WAb
 QNJUxknjuDMAPKyHHXHLG1lte1BMs+QaAtwujD/OMc2Vz9lwngbmIT3
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document cvm_oct_sgmii_open() and cvm_oct_sgmii_init() by adding standard
kernel-doc comment blocks. This fixes styling inconsistencies across the
octeon staging subsystem and allows documentation scripts to correctly
parse the function parameters and return values.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-sgmii.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/staging/octeon/ethernet-sgmii.c b/drivers/staging/octeon/ethernet-sgmii.c
index d7fbd9159302..2cd717709414 100644
--- a/drivers/staging/octeon/ethernet-sgmii.c
+++ b/drivers/staging/octeon/ethernet-sgmii.c
@@ -16,11 +16,23 @@
 #include "ethernet-util.h"
 #include "ethernet-mdio.h"
 
+/**
+ * cvm_oct_sgmii_open - open the SGMII interface
+ * @dev:    Net device to open
+ *
+ * Return: Zero on success
+ */
 int cvm_oct_sgmii_open(struct net_device *dev)
 {
 	return cvm_oct_common_open(dev, cvm_oct_link_poll);
 }
 
+/**
+ * cvm_oct_sgmii_init - initialize the SGMII interface
+ * @dev:    Net device to initialize
+ *
+ * Return: Zero on success
+ */
 int cvm_oct_sgmii_init(struct net_device *dev)
 {
 	cvm_oct_common_init(dev);

-- 
2.56.0

