From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH v2 0/5] common fixes
Date: Sun, 30 Jun 2024 23:52:39 +0200
Message-Id: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKfTgWYC/x3LQQqAIBBA0avIrBsQydCuEi1Mp5qFGgoRSHdPW
 j4+v0GlwlRhFg0K3Vw5pw41CPCnSwchh25QUo1yUhZ9jjEn3PmhitJpr03YjPYW+nIV+kM/lvV
 9Pw+C1MBeAAAA
To: fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Zorro Lang <zlang@redhat.com>, 
 mcgrof@kernel.org, gost.dev@samsung.com, 
 Samsung Samsung <"Daniel Gomez d+samsung"@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719784382; l=1524;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=W9yldUhak0oAQZf4+rXraGneHoRaHA4kFtGk2/atIjE=;
 b=q+x9dejRfzUC+9wzwKiVMLyiBIMNd/9zPRaTk6iGiGrQRwIrRczenZCdjFfesZxdeRGynfOA9
 8vTMAmmkD77DS/WQkTA+eOV9xmYB9J0ZMS+G4Il/Z/nPFUjtCrgnCf+
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Config section fixes for scratch and recreation test devices.

Changes since v1:
* Drop tmpfs/449 patch.
Note: I will submit it in a different series with the feedback received.
* Applied review tags from Darrick and Zorro for patch 1.
* Do not inject specific TMPFS mount options in recreation and scratch
mount options. Instead,
  * Fix recreation test device by allowing section parsing to read
specific fs mount options when RECREATE_TEST_DEV is enabled.
  * Use _common_mount_opts() for scratch mounts instead of
_common_dev_mount_options() to allow parsing section fs specific mount
options for scratch devices.
* print only test mkfs and mount devices instead of adding scratch and
test sections.
* Add/export and report new TEST_MKFS_OPTIONS and TEST_MOUNT_OPTIONS.
* Change patch series subject.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (5):
      common/config: fix RECREATE_TEST_DEV initialization
      common/rc: add recreation support for tmpfs
      common/config: enable section parsing when recreation
      common/rc: read config section mount options for scratch devs
      common/rc: print test mount options

 check         |  2 ++
 common/config |  4 ++--
 common/rc     | 26 +++++++++++++++++++++++---
 common/report |  1 +
 4 files changed, 28 insertions(+), 5 deletions(-)
---
base-commit: 83598d2f839d9c27d2fd4209124d7c288ea2861e
change-id: 20240629-common-fixes-0a5c58db85c9

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

