From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 20:07:58 -0600
Subject: [PATCH 4/4] staging: octeon: fix IRQ leak error path and remove
 dst.h from ethernet-spi.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-phy-series-v2-v1-4-d7ab0b4b3f17@gmail.com>
References: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
In-Reply-To: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794103676; l=1371;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=R/oKIlw7zjOe4R9w3qzlWN0J7x8RLy9bbUrOjNfj+Cs=;
 b=ycL/v3qP6qmuTouVF+wEqXfmlomp+Zc3Ei01cVp8NvU0Jl9UNxJkTCm8UdFhftsom8hmKvKJj
 Zs3PNjOT33RDIGAdXXcl9xH/OP/Ll1cKxiXgKBplSJkY9km2KOEes/D
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a resource leak in cvm_oct_spi_init() by properly validating the
return value of cvm_oct_common_init(). If the common initialization
fails, perform a rollback by decrementing the spi port counter and
releasing the shared RML interrupt handler via free_irq().

Additionally, clean up the file header by removing the unused inclusion
of <net/dst.h>.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-spi.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-spi.c b/drivers/staging/octeon/ethernet-spi.c
index 699c98c5ec13..e6ebc879ccad 100644
--- a/drivers/staging/octeon/ethernet-spi.c
+++ b/drivers/staging/octeon/ethernet-spi.c
@@ -8,7 +8,6 @@
 #include <linux/kernel.h>
 #include <linux/netdevice.h>
 #include <linux/interrupt.h>
-#include <net/dst.h>
 
 #include "octeon-ethernet.h"
 #include "ethernet-defines.h"
@@ -206,7 +205,14 @@ int cvm_oct_spi_init(struct net_device *dev)
 		cvm_oct_spi_enable_error_reporting(INTERFACE(priv->port));
 		priv->poll = cvm_oct_spi_poll;
 	}
-	cvm_oct_common_init(dev);
+	r = cvm_oct_common_init(dev);
+	if (r) {
+		number_spi_ports--;
+		if (number_spi_ports == 0)
+			free_irq(OCTEON_IRQ_RML, &number_spi_ports);
+		return r;
+	}
+
 	return 0;
 }
 

-- 
2.56.0

