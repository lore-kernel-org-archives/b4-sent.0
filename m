From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Fri, 06 Nov 2026 23:55:27 -0600
Subject: [PATCH] staging: octeon: fix parameter alignment in octeon-stubs.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261106-octeon-stubs-align-v1-1-1257ff90bcbc@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avErBtQA/u5SrQwm2ogNJyKILp70
 vJbvPeAUGIS6IoHEl0sHEOGLgvwqwsLIU/ZYJSxWiuL0R8UA8pxjoJu4yWgatvaW91MdWUgh3u
 ime9/2g/v+wHvEWZgZAAAAA==
X-Change-ID: 20261106-octeon-stubs-align-0997c618d732
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794030928; l=1315;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=h+4iwZR2O9qgdWzGe2/8EkE8ODQ/38WUsFjZx8jrl/M=;
 b=ggyo2EnwigUGHf6hrrVHiW6MGKlSCH9E3lqoIg/8HfaWKoH8WPi/l5WYH4hJEqMDdB3zycNNF
 ikplnFgPhzNDH5V7cZp1eAdCLAITt+kw5/nkKcW5hkI1Ux8FkX3ESvw
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wrap cvmx_pko_send_packet_finish() declaration to align parameters
with the opening parenthesis while keeping line lengths within limits.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
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
change-id: 20261106-octeon-stubs-align-0997c618d732

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

