From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Wed, 11 Nov 2026 16:36:11 -0600
Subject: [PATCH v3] staging: octeon: fix FPA output buffer pool leak on
 teardown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261111-octeon-fpa-leak-fix-v1-v3-1-17a3bd578f76@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNwQqDMBBEf0X23C1uFI099T+KhzSuulSNJCItk
 n9v6g8U5vJmmJkDAnvhALfsAM+7BHFLguKSgR3NMjBKlxhUriqiXKOzG7sF+9XgxOaFvbxxJzT
 UFcRNra1WkMqr55Scw4828Shhc/5z/uz0c/9OJhFqNuWzbOqKc3UfZiPT1boZ2hjjFxj1wjS8A
 AAA
X-Change-ID: 20261108-octeon-fpa-leak-fix-v1-a1d31e978c82
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794436571; l=2498;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=VsRJsJ5u/AeZd4M/f4kMGa+p6KbxKOVR4bmA4sspaeo=;
 b=FkRMy4Coc2K/wSuYzU3NxfRtZMrUSizT1i/oaecJONEppMZYrctq5AYVw7Lr4Er+HAApXep7P
 R0VPTcgJ7J3Cn+wVT1/vKfgen06NzscdWWuU5Rwf7/8kVnzhkxl4aYI
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_configure_common_hw() fills CVMX_FPA_OUTPUT_BUFFER_POOL with
1024 buffers, but cvm_oct_probe() and cvm_oct_remove() only empty 128
buffers, leaking the remaining 896.

Introduce OCTEON_NUM_OUTPUT_BUFFERS to fill and empty all 1024 buffers
consistently.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (1):
  staging: octeon: fix FPA output buffer pool leak on teardown
---
Changes in v3:
- Clarify commit message.
- Validate cross-compilation for MIPS64.
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
change-id: 20261108-octeon-fpa-leak-fix-v1-a1d31e978c82

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

