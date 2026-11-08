From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Subject: [PATCH 0/3] Subject: [PATCH 0/3] staging: octeon: Fix
 initialization pathways, parsing, and modernize statistics
Date: Sun, 08 Nov 2026 05:48:59 -0600
Message-Id: <20261108-octeon-init-pipeline-v1-v1-0-eb2c6c956279@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQqDMBBF0V+RWXfARCu2v1K6KOmzfSCTkIgI4
 r8bXJ7FvbsUZKLIs9klY2VhtAp3ayT8P/aD8lstvvWDc+2oMSyIpjQumpgw06CrU/g7wtBP/QO
 d1DplTNyu8+t9HCedG/ndaQAAAA==
X-Change-ID: 20261108-octeon-init-pipeline-v1-e25ec64f49e3
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794138540; l=1714;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=w+LxKXpc5/OueBx6E2vSnL8lEwk3W2G5TdRTpGXBCVA=;
 b=4IlX1Expen/V/qIyYipHD40SSx4qgmLDskV1to9gu6SYOp5F7ytQkD9/mHgUh8iHz41vEYbh4
 w4V7QgSZJsOA60hYXKFZtCkYWrEZrkuymcg41qrzlL/gtDrBeYbFbOX
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series resolves critical initialization issues, structural edge cases 
in string tokenization, and infrastructure modernizations within the core 
ethernet interface logic of the Cavium Octeon staging driver (ethernet.c).

1. Fix a missing hardware resource cleanup step in the cvm_oct_probe() error 
   handling path by ensuring cvmx_pko_disable() is invoked dynamically prior 
   to device detachment.
2. Replace an unsafe prefix-matching strstr() evaluation within the 
   pow_send_list check with accurate comma-separated tokenization using 
   strsep() and strict strcmp() checking.
3. Migrate the legacy 32-bit ndo_get_stats net_device_ops callback to the 
   modern 64-bit ndo_get_stats64 atomic interface infrastructure to prevent 
   counter wrap-around bugs on SMP platforms.

Oscar Alejandro Sánchez Lucero (3):
  staging: octeon: disable PKO before device removal in probe error path
  staging: octeon: match exact interface names in pow_send_list
  staging: octeon: convert from ndo_get_stats to ndo_get_stats64

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Oscar Alejandro Sánchez Lucero (3):
      staging: octeon: disable PKO before device removal in probe error path
      staging: octeon: convert from ndo_get_stats to ndo_get_stats64
      staging: octeon: match exact interface names in pow_send_list

 drivers/staging/octeon/ethernet.c | 55 +++++++++++++++++++++++++--------------
 1 file changed, 36 insertions(+), 19 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261108-octeon-init-pipeline-v1-e25ec64f49e3

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

