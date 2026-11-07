From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 00:39:47 -0600
Subject: [PATCH] staging: octeon: fix FPA output buffer pool leak on
 teardown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-fpa-pool-fix-v1-1-1c87ab050a2b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bkENUvpKdLBaayFc0Ygg+nvSc
 QZmHiiUmQoMzQOZLi4ssYJuG1h2HzdCXiuDUabXWlmU5SSJGJLHJHJg4BvXeXbWG9WFzkEtU6a
 q/+s4ve8HiJnCMGUAAAA=
X-Change-ID: 20261107-octeon-fpa-pool-fix-dbb87a203f38
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794033587; l=2396;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=jfYK6mu4CymzOqkHn43J/TUYukLoXz0XWFvyyqJ4PXI=;
 b=iWqfh3jt+pJDZzI6sXfPmTV874QAs/4gWGseyD+GrXOhKpSR+UdB1tmWdNVE1N6FWGKq20DJm
 dN6pjIadwiwCVcOM9au+IG4NwOi1+kU2fVEgcEjAJVKqEaVfhiQqzoP
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_configure_common_hw() allocates 1024 buffers for
CVMX_FPA_OUTPUT_BUFFER_POOL, but both the probe error path and
cvm_oct_remove() only free 128 buffers when calling
cvm_oct_mem_empty_fpa(), leaking 896 buffers on driver teardown.

Define OCTEON_NUM_OUTPUT_BUFFERS as 1024 and use it consistently when
filling and emptying CVMX_FPA_OUTPUT_BUFFER_POOL.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..a74d122d9bb1 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -29,6 +29,7 @@
 #include "ethernet-util.h"
 
 #define OCTEON_MAX_MTU 65392
+#define OCTEON_NUM_OUTPUT_BUFFERS 1024
 
 static int num_packet_buffers = 1024;
 module_param(num_packet_buffers, int, 0444);
@@ -162,7 +163,8 @@ static void cvm_oct_configure_common_hw(struct platform_device *pdev)
 			     num_packet_buffers);
 	if (CVMX_FPA_OUTPUT_BUFFER_POOL != CVMX_FPA_PACKET_POOL)
 		cvm_oct_mem_fill_fpa(pdev, CVMX_FPA_OUTPUT_BUFFER_POOL,
-				     CVMX_FPA_OUTPUT_BUFFER_POOL_SIZE, 1024);
+				     CVMX_FPA_OUTPUT_BUFFER_POOL_SIZE,
+				     OCTEON_NUM_OUTPUT_BUFFERS);
 
 #ifdef __LITTLE_ENDIAN
 	{
@@ -974,7 +976,8 @@ static int cvm_oct_probe(struct platform_device *pdev)
 			      num_packet_buffers);
 	if (CVMX_FPA_OUTPUT_BUFFER_POOL != CVMX_FPA_PACKET_POOL)
 		cvm_oct_mem_empty_fpa(pdev, CVMX_FPA_OUTPUT_BUFFER_POOL,
-				      CVMX_FPA_OUTPUT_BUFFER_POOL_SIZE, 128);
+				      CVMX_FPA_OUTPUT_BUFFER_POOL_SIZE,
+				      OCTEON_NUM_OUTPUT_BUFFERS);
 
 	return ret;
 }
@@ -1009,7 +1012,8 @@ static void cvm_oct_remove(struct platform_device *pdev)
 			      num_packet_buffers);
 	if (CVMX_FPA_OUTPUT_BUFFER_POOL != CVMX_FPA_PACKET_POOL)
 		cvm_oct_mem_empty_fpa(pdev, CVMX_FPA_OUTPUT_BUFFER_POOL,
-				      CVMX_FPA_OUTPUT_BUFFER_POOL_SIZE, 128);
+				      CVMX_FPA_OUTPUT_BUFFER_POOL_SIZE,
+				      OCTEON_NUM_OUTPUT_BUFFERS);
 }
 
 static const struct of_device_id cvm_oct_match[] = {

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-fpa-pool-fix-dbb87a203f38

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

