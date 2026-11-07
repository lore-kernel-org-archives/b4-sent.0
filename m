From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Subject: [PATCH 0/2] staging: octeon: cleanups and safety fixes in
 ethernet-tx.c
Date: Sat, 07 Nov 2026 05:28:39 -0600
Message-Id: <20261107-octeon-tx-fixes-v1-0-db03f73a6e6f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3LQQqAIBBA0avIrBtQg4SuEi1Kx5qNhkoI4t2Tl
 o/Pb5ApMWVYRYNEL2eOYUBNAux9hIuQ3TBoqRelpMFoC8WApaLnShlPb6Sjw9jZSRjXk+gPY9r
 23j8TyfwQYQAAAA==
X-Change-ID: 20261107-octeon-tx-fixes-bf70dea7c3d0
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794050920; l=1114;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=lcykt2LPE/WQKcgUfJaa7HPuicjvt716I0sbmIoXVzE=;
 b=Am/7jX6++4pD5tvnaGcE0vNJ7RNe7xi8YPnF8TVpfCMDO3Z4CTjnLJ2lLSE1g8d3YpBVBsNYz
 r8hGAV5qIvMDyUKUVw/D5/bzeNgcnpouxLrnv30jlNq3+7MSrKHSkP4
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes memory safety and API correctness issues found in
drivers/staging/octeon/ethernet-tx.c during static analysis:

1. Fix return types in cvm_oct_xmit_pow() to use NETDEV_TX_OK instead of
   naked integer '0', and change pointers to u8 * to avoid non-standard
   void pointer arithmetic warnings.
2. Add packet length validation to avoid a buffer overflow when copying
   into the FPA packet pool, and bound WQE data memcpys with min_t() to
   prevent out-of-bounds reads on short/malformed frames.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (2):
      staging: octeon: fix return type and void arithmetic in cvm_oct_xmit_pow()
      staging: octeon: prevent buffer overflow in cvm_oct_xmit_pow()

 drivers/staging/octeon/ethernet-tx.c | 34 ++++++++++++++++++++++------------
 1 file changed, 22 insertions(+), 12 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-tx-fixes-bf70dea7c3d0

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

