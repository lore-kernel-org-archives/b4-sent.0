From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH 0/5] guestfs: bringup: add debug mode
Date: Tue, 15 Oct 2024 13:34:50 +0200
Message-Id: <20241015-bringup-guestfs-debug-v1-0-bd74c0c31412@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFpTDmcC/x3MQQqAIBBA0avErBvQKKyuEi0yR5uNhZMRRHdPW
 r7F/w8IJSaBsXog0cXCeyzQdQXrtsRAyK4YGtW0WukObeIY8oEhk5xe0JHNAY3pfOusG/pVQ2m
 PRJ7v/zvN7/sB5N1AYmcAAAA=
X-Change-ID: 20241015-bringup-guestfs-debug-775f4dbd98c1
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.com>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728992109; l=1461;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=beIA6sxyPtDDEt1OujY0XfJVP59rqeokjZXB98MAFS8=;
 b=dWZhSP0WT3I+tpydK7ruqWc8WEbeDPC3YKoPEqg3BQSj6LrprF9T3/fwtlc3u1ULFuiu9r26U
 q5Qw3RLzHisDCrNYfB+BfK6InEkRXp8BAHwO5cQxz+DfNEeou6XfVmB
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding debug option in bash bringup_guestfs.sh allows to check for
commands executions (virsh, chmod, cp, virt-sysprep, etc) and variables.

Add 3 levels of debug:
- Disabled: This is the current behaviour and is the default.
- set -x (debug mode 0):  Allows to print the executed commands but if
they fail, the script continues.
- set -euxo pipefail (debug mode 1): mode 0 + variables are printed +
script fails if a command does not succeed.

While debugging, I noticed about small bash errors that we ignore, such
as unbound variables. So, this also fixes the issues found while debug
mode 1 was enabled.

To: kdevops@lists.linux.dev
To: Luis Chamberlain <mcgrof@kernel.com>
Cc: Daniel Gomez (Samsung) <d+samsung@kruces.com>

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (5):
      scripts: lib: rename KDEVOPS_WORKFLOW_FSTESTS
      guestfs: bringup: check if domain exists
      guestfs: bringup: fix unbound variable when debug
      guestfs: bringup: fix user check when debug
      guestfs: bringup: add debug mode

 kconfigs/Kconfig.guestfs   | 21 +++++++++++++++++++++
 scripts/bringup_guestfs.sh | 31 ++++++++++++++++++++-----------
 scripts/lib.sh             |  2 +-
 3 files changed, 42 insertions(+), 12 deletions(-)
---
base-commit: 5b4d19d8e8ed606c3e64e0679f3792504cc31207
change-id: 20241015-bringup-guestfs-debug-775f4dbd98c1

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

