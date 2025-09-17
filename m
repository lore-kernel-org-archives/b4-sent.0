From: Theodore Ts'o <tytso@mit.edu>
Subject: [PATCH v2 0/3] ext4: Add support for mounted updates to the
 superblock via an ioctl
Date: Tue, 16 Sep 2025 23:22:46 -0400
Message-Id: <20250916-tune2fs-v2-0-d594dc7486f0@mit.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIYpymgC/z3MQQ6CMBCF4auQWVtTOhaoK+9hWIBMZRYW05ZGQ
 3p3KyYu/5eXb4NAninAudrAU+LAiyuhDhXc5sHdSfBUGpRUWnYoRVwdKRsEYtuMNLbqJBHK++n
 J8muXrn3pmUNc/HuHU/1df4aR3d9ItZCCcGiMMhZR68uD45GmFfqc8wfvNwsPnAAAAA==
X-Change-ID: 20250830-tune2fs-3376beb72403
To: tytso@mit.edu
Cc: linux-ext4@vger.kernel.org, linux-api@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1459; i=tytso@mit.edu;
 h=from:subject:message-id; bh=s+Ah/AAHowwzNuuce/f6c/Q+zdGsP5DuTh81rmB8SBY=;
 b=owEBbQGS/pANAwAIAfL5WVaVDYGjAcsmYgBoyimjM4Q785OEKu5sS5LIuhYhQqyZ/H7GzG6P4
 nHx/gaBbaCJATMEAAEIAB0WIQQrablU2/4IeSiBN8ny+VlWlQ2BowUCaMopowAKCRDy+VlWlQ2B
 o3dRB/9NpXGyTbbc0Uf8y4v3AtNFRwxLY/srg37XORX9wOm/lAn2ZpAfIWhMGSFmPLzSpJgkTen
 8suE4uFvY+v+NLMDq3EPOFzVETckm+rjGTXU+m9FtD/TZKTfhQUiZcItf1CmBQ23ZcQplXuq00n
 crc4oUdEKw6ikCXCyQSQUXEVld0idq2Siknairp57zCZRIgP4pjj3HIKDNGb2ycWoTDV/nmT/lW
 Ui8QGlDk4wHSvX1g/BqWmAR/wMi1RBdaYinnODJKmIEsoNzBU7AJzpv8Wgxr7FPzTNIHwKmJ4j7
 PUioF0yqeJu/MG9ZvEHFcYNaP8XshrCLHQaYZJCwsS5qDACy
X-Developer-Key: i=tytso@mit.edu; a=openpgp;
 fpr=3AB057B7E78D945C8C5591FBD36F769BC11804F0
X-Endpoint-Received: by B4 Relay for tytso@mit.edu/default with auth_id=517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series enables a future version of tune2fs to be able to
modify certain parts of the ext4 superblock without to write to the
block device.

The first patch fixes a potential buffer overrun caused by a
maliciously moified superblock.  The second patch adds support for
32-bit uid and gid's which can have access to the reserved blocks pool.
The last patch adds the ioctl's which will be used by tune2fs.

Signed-off-by: Theodore Ts'o <tytso@mit.edu>
---
Changes in v2:
- fix bugs that were detected using sparse
- remove tune (unsafe) ability to clear certain compat faatures
- add the ability to set the encoding and encoding flags for case folding
- Link to v1: https://lore.kernel.org/r/20250908-tune2fs-v1-0-e3a6929f3355@mit.edu

---
Theodore Ts'o (3):
      ext4: avoid potential buffer over-read in parse_apply_sb_mount_options()
      ext4: add support for 32-bit default reserved uid and gid values
      ext4: implemet new ioctls to set and get superblock parameters

 fs/ext4/ext4.h            |  16 +++-
 fs/ext4/ioctl.c           | 312 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
 fs/ext4/super.c           |  25 +++----
 include/uapi/linux/ext4.h |  53 +++++++++++++
 4 files changed, 382 insertions(+), 24 deletions(-)
---
base-commit: b320789d6883cc00ac78ce83bccbfe7ed58afcf0
change-id: 20250830-tune2fs-3376beb72403

Best regards,
-- 
Theodore Ts'o <tytso@mit.edu>

