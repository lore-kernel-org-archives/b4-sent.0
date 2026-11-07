From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Subject: [PATCH 0/2] staging: octeon: cleanups and error handling fixes in
 ethernet-rx.c
Date: Sat, 07 Nov 2026 05:06:43 -0600
Message-Id: <20261107-octeon-rx-fixes-v1-0-f5a21907c8af@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3LSwqAMAwA0atI1gasaP1cRVxIGzWbVlKRQvHuB
 pfDYwokEqYEc1VA6OHEMWiYugJ3buEgZK8NbdNaY5oBo7spBpSMO2dK6Ds/WNV+dBPodQn9oNO
 yvu8H51ZF42EAAAA=
X-Change-ID: 20261107-octeon-rx-fixes-d4d7620258c9
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794049605; l=1019;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=D5d2ygIHv0epXdIMouTlsArAE5BONbBw3JoOcji/dCg=;
 b=hV4x2eerX2c4xC+Zhauxt2hWbBfMDcy8r0HLBMkbIZai01KEPQthaiicNiXHOaUuxw/8125R4
 opd8RYziaRMDLl1RSP1Ctssj5mGtZBVCYZYt/EYeWnit03xSkVA7691
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes a couple of issues found during code review and static
analysis of drivers/staging/octeon/ethernet-rx.c:

1. Avoid non-standard GCC pointer arithmetic on void * in cvm_oct_poll()
   by casting to u8 * first.
2. Add a proper error rollback path in cvm_oct_rx_initialize() so that
   NAPI instances, interrupts, and POW/SSO registers from previous loop
   iterations are properly cleaned up if request_irq() fails.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (2):
      staging: octeon: avoid void pointer arithmetic in ethernet-rx.c
      staging: octeon: fix error handling rollback in cvm_oct_rx_initialize()

 drivers/staging/octeon/ethernet-rx.c | 26 +++++++++++++++++++++-----
 1 file changed, 21 insertions(+), 5 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-rx-fixes-d4d7620258c9

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

