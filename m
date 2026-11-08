From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sun, 08 Nov 2026 06:22:17 -0600
Subject: [PATCH] staging: octeon: fix parameter alignment in octeon-stubs.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261108-octeon-stubs-alignment-v1-v1-1-bafda8c63890@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQ6CMBBG4auQWTsJ7aKgVzEuaPnFSXRqOoWYE
 O5uw/JbvLeToQiMbt1OBZuYZG1wl47Sa9IFLHMz+d4H5/qRc6rIylbXaDy9ZdEPtPLmGCmMVz9
 jiDFQ678FT/md7/vjOP5Fy77AawAAAA==
X-Change-ID: 20261108-octeon-stubs-alignment-v1-ec6892de7bb6
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794140538; l=1698;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=JhZbbg8mmsWsZGrss6itWiBifitqXmu5fPEs6ExXPGM=;
 b=97IOllAc7FI5DXvg50t2Si1YgrP1oxIp9SGhWaB+djwiNnLE767P5ojNp74IlZ/XEUI4/CYLr
 pkRoZ5zUHHIDU7VRKtf4uQxGZbPBwf8x4moO5h1IJQrLh4YvCiCoKL6
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wrap cvmx_pko_send_packet_finish() declaration to align parameters
with the opening parenthesis while keeping line lengths within limits.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
This patch improves human readability and code style consistency across the 
stub declarations of the Cavium Octeon network driver.

1. Wrap and properly indent cvmx_pko_send_packet_finish() parameters to 
   align cleanly with the function's opening parenthesis.

Oscar Alejandro Sánchez Lucero (1):
  staging: octeon: fix parameter alignment in octeon-stubs.h
---
 drivers/staging/octeon/octeon-stubs.h | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/staging/octeon/octeon-stubs.h b/drivers/staging/octeon/octeon-stubs.h
index 9c1968b7e2d1..7fcafabdc78b 100644
--- a/drivers/staging/octeon/octeon-stubs.h
+++ b/drivers/staging/octeon/octeon-stubs.h
@@ -1386,9 +1386,11 @@ static inline void cvmx_pko_send_packet_prepare(u64 port, u64 queue,
 						enum cvmx_pko_lock use_locking)
 { }
 
-static inline enum cvmx_pko_status cvmx_pko_send_packet_finish(u64 port,
-		u64 queue, union cvmx_pko_command_word0 pko_command,
-		union cvmx_buf_ptr packet, enum cvmx_pko_lock use_locking)
+static inline enum cvmx_pko_status
+cvmx_pko_send_packet_finish(u64 port, u64 queue,
+			    union cvmx_pko_command_word0 pko_command,
+			    union cvmx_buf_ptr packet,
+			    enum cvmx_pko_lock use_locking)
 {
 	return 0;
 }

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261108-octeon-stubs-alignment-v1-ec6892de7bb6

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

