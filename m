From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Subject: [PATCH v4 0/2] staging: octeon: fix probe error path and
 pow_send_list matching
Date: Wed, 11 Nov 2026 21:48:31 -0600
Message-Id: <20261111-octeon-init-pipeline-v1-v4-0-5b4f8e613ae1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNwQqDMAyA4VeRnNdha1vtTnuPsYProgZcK62UD
 fHdVz15GYNc/kC+LBAxEEa4FAsETBTJuxzyVIAdWtcjo2duEKXQnJcN83ZG7xg5mtlEE47kkCX
 OUCi0WnbSYAX5egrY0XuXb/fcA8XZh8/+KPFt+9/MUzJ8CKutUVrU5tq/WhrP1r9gM1N1cDj/7
 VSbo1TDTS27FuXRWdf1CzsENboGAQAA
X-Change-ID: 20261108-octeon-init-pipeline-v1-e25ec64f49e3
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794455321; l=1217;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=pfWq9ciDcNTGRqmqjjmBm1Xv8yHjO6TCvax7c9j/9Ic=;
 b=/dqSCqxog6vMel5jfAcPKvMGn2qelPeRikBEBJDEhqQKuyLWo5BUM++uzPbZEP6q26FW0J4u+
 sgU5qXdMn9GAbDR8v3kDJleOFHHjH+zxBXfERnnlKiWX1uuUll0PlX8
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixed two bugs in drivers/staging/octeon/ethernet.c:

1. Call cvmx_pko_disable() in the cvm_oct_probe() error path to match the
   teardown sequence in cvm_oct_remove().
2. Split pow_send_list on commas using strsep() instead of matching
   substrings with strstr().

Oscar Alejandro Sánchez Lucero (2):
  staging: octeon: disable PKO before device removal in probe error path
  staging: octeon: match exact interface names in pow_send_list

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Changes in v4:
- Build tested on mips64 (cavium_octeon_defconfig) with W=1.
- Link to v3: https://lore.kernel.org/r/20261111-octeon-init-pipeline-v1-v3-0-e5581974fae4@gmail.com

---
Oscar Alejandro Sánchez Lucero (2):
      staging: octeon: disable PKO before device removal in probe error path
      staging: octeon: match exact interface names in pow_send_list

 drivers/staging/octeon/ethernet.c | 22 +++++++++++++++++++---
 1 file changed, 19 insertions(+), 3 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261108-octeon-init-pipeline-v1-e25ec64f49e3

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

