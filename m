From: Theodore Ts'o <tytso@mit.edu>
Subject: [PATCH 0/3] ext4: Add support for mounted updates to the
 superblock via an ioctl
Date: Mon, 08 Sep 2025 23:15:47 -0400
Message-Id: <20250908-tune2fs-v1-0-e3a6929f3355@mit.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOObv2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC2MD3ZLSvFSjtGJdY2Nzs6TUJHMjEwNjJaDqgqLUtMwKsEnRsbW1AC8
 hKOBZAAAA
X-Change-ID: 20250830-tune2fs-3376beb72403
To: tytso@mit.edu
Cc: linux-ext4@vger.kernel.org, linux-api@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1179; i=tytso@mit.edu;
 h=from:subject:message-id; bh=1fjgACFxa8qJDM7j3UWs9Km/opZNhb3lTBI8Xu1OGyg=;
 b=owGbwMvMwMH46Wdk2FTexsWMp9WSGDL2z37amhR5d7YIL+9tpcoppX+bO1z80w/2n7PLnzexJ
 SqUefrOTkZjFgZGDgZZMUUW7cydIbf/cVRqNJqfhBnEygQyhYGLUwAmwuDO/j/uTsW951WVn5d4
 fz1s0nN9tuzjaS9VRL8bRmw7u/DHrfLY5rl95qXrP78V+BW45nKWUPpe7cnbk1dkvK8Q/b/3jsy
 ZB/wKnD2CjgzfQvWSCvXUZzDP+JgaopYYEMmjtMBw+aGo8Hl9zGnuy531n60qCkmsTed7kzQxuU
 bjYKOq2Wq1utJCkRW2R+7Yn27OcnvIdbji/y2ml7dWqEu+njs1WSo1J6LEIt4/7r8U64U9obVt3
 VevagvHqx6Kaf3pxaS76cQcnzSddVccLXOSNkbZB6b616+/7Su756mNgg67o/oB7v8HVv7ozpfx
 EUk1l5yu/NEo5MdDhi9m2v2N90TucqtPv3Oi59X07xquAA==
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
Theodore Ts'o (3):
      ext4: avoid potential buffer over-read in parse_apply_sb_mount_options()
      ext4: add support for 32-bit default reserved uid and gid values
      ext4: implemet new ioctls to set and get superblock parameters

 fs/ext4/ext4.h            |  16 ++++-
 fs/ext4/ioctl.c           | 256 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++---
 fs/ext4/super.c           |  25 +++-----
 include/uapi/linux/ext4.h |  75 ++++++++++++++++++++++
 4 files changed, 348 insertions(+), 24 deletions(-)
---
base-commit: b320789d6883cc00ac78ce83bccbfe7ed58afcf0
change-id: 20250830-tune2fs-3376beb72403

Best regards,
-- 
Theodore Ts'o <tytso@mit.edu>

