From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 09:24:53 -0600
Subject: [PATCH] staging: octeon: add kernel-doc to ethernet-sgmii.c
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-sgmii-fixes-v1-1-7a5b0fe7d830@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3LQQqAIBBA0avIrBtQi6KuEi3MpppFGk5EIN09a
 fn4/AxCiUlgUBkS3SwcQ4GpFPjdhY2Ql2Kw2rbG6A6jvygGlO1gxpUfEnR9PZtm1Y3vPJTxTPS
 H8o3T+3491QgeZAAAAA==
X-Change-ID: 20261107-octeon-sgmii-fixes-a93b14f04c7c
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794065093; l=1423;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=UMDYflhe5DeZfL7ZUgNBxR1G7QGPyWtztw2kj8SfazU=;
 b=2jhsNCj8V23riUFLlbR3NbdlBXGlGBN8PCCNf/+fDNzpalgM/lc9l1OVLgk5k6/6QzR7VbOT8
 a19xdGTxT3BAxIimYjZ9Qyc3ak7LlmIBAzHvZ6j1oqZgh6jirc9jaLN
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

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-sgmii-fixes-a93b14f04c7c

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

