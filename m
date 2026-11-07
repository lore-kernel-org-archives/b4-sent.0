From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 05:06:44 -0600
Subject: [PATCH 1/2] staging: octeon: avoid void pointer arithmetic in
 ethernet-rx.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-rx-fixes-v1-1-f5a21907c8af@gmail.com>
References: <20261107-octeon-rx-fixes-v1-0-f5a21907c8af@gmail.com>
In-Reply-To: <20261107-octeon-rx-fixes-v1-0-f5a21907c8af@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794049605; l=898;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=d07dfZQ1mRZaecgAH10Camw1oIZYGakZzv16T/1D2jw=;
 b=1XkCK8Y3B9ldNTpHNTw4bH2281ZAg8zTtm1mJ65EAFbSp1MT7rg9wRyJf94od5Pyfxc+REaqU
 Lp4ekxMkGMKDd8aazAj21qavKlpd8kj+h/gTZxvmvFK7ZWtkOnACUZy
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Arithmetic on void pointers is a non-standard GCC extension and
triggers -Wpointer-arith warnings. Cast the buffer pointer
returned by cvm_oct_get_buffer_ptr() to u8 * before subtracting
the offset.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-rx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/staging/octeon/ethernet-rx.c b/drivers/staging/octeon/ethernet-rx.c
index 5be43bbf6a1d..b0463759be39 100644
--- a/drivers/staging/octeon/ethernet-rx.c
+++ b/drivers/staging/octeon/ethernet-rx.c
@@ -243,7 +243,7 @@ static int cvm_oct_poll(struct oct_rx_group *rx_group, int budget)
 			break;
 		}
 		pskb = (struct sk_buff **)
-			(cvm_oct_get_buffer_ptr(work->packet_ptr) -
+			((u8 *)cvm_oct_get_buffer_ptr(work->packet_ptr) -
 			sizeof(void *));
 		prefetch(pskb);
 

-- 
2.56.0

