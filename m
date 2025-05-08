From: Chen Linxuan <chenlinxuan@uniontech.com>
Subject: [PATCH v2 0/3] fuse: Expose more information of fuse backing files
 to userspace
Date: Thu, 08 May 2025 16:53:43 +0800
Message-Id: <20250508-fusectl-backing-files-v2-0-62f564e76984@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABdxHGgC/zWOwQqDMBBEf0Vy7sq6otGe+h/Fg42rWWpjSVQs4
 r83FXp8A/NmdhXYCwd1TXbleZUgk4tAl0QZ27qBQbrIipAKLLCCfgls5hEerXmKG6CXkQOUVYY
 d1ci6rlTsvj33sp3eexPZSpgn/zln1uyX/o0ac6qpTHOtUZdAYCy7Udy2tO62uHhnZmNTM71Uc
 xzHF97ZToOxAAAA
X-Change-ID: 20250508-fusectl-backing-files-6810d290e798
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1460;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=EefenSng1ckhszoQFgYawbUMHZnq3C6b7k2QovafbEU=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoHHEeWQ45itwERzLYrNzAswRnl5y/AU4mRxJmF
 bniqrasptCJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBxxHgAKCRB2HuYUOZmu
 izvNEADRmsQWebLMMUC28QwvIbCU0ZVKYx6ZBDqsh/X+UJ3rse8Wtg8BWE8krz1+38ncNvIsU3E
 ajQ2dED/IzDHx0rga/yRFbRWy0n7O66avYwcKgY9R0yu6iSkOaRTtQTixX9EkRQMG4GjroNQoci
 zNO1UL15EoU+jHG9FQXtu+DCUzui04dzyAT4w9DRDWAJDyi2LjdACc2LLSvqlx+p0So0yvZsa3M
 5UsBhXmCXO+p6F8GxzPOA/Jkzg50U3ISG+Rtd+iGpiDALEwv3tfHOr6i31LmqJ8mp7ho65uvL9o
 RKyCQBXT2TPpS4CLu0PachovyeiAdSxXgNVq4zTtCzHHJYIGuQ8pl/jq09ubvs6IgKiylYGXjjE
 DWgFKVAkNvo8uifXtH6W/cXNXLqPI1dpW0X5yVEQ4D8PgKJHigCYMxjeITPBPYULlAJzCXDT+NF
 yv3P8WvTt8Xvwx7yN93ijFGHR8IY6aVsniCPDJazvGrFD88tdqPTbFkcEG4lj09f5JUBABbj12p
 zNwT3dZvPRtqDvLi7pnV+GHteFDLVegJwWc2jknDyDJq/LV46o7HKEtvYvikHkG3d7Bj7y6DZsh
 1bBSIAOjfm7OB/SOBwdiNjjg5g1yDBRaIVJAfILaape70uW4mCVCV+LqhAowpREOxNBREs12b/q
 wHktPdWe62/zDUw==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Please review this patch series carefully. I am new to kernel
development and I am not quite sure if I have followed the best
practices, especially in terms of seq_file, error handling and locking.
I would appreciate any feedback.

I have do some simply testing using libfuse example [1]. It seems to
work well.

[1]: https://github.com/libfuse/libfuse/blob/master/example/passthrough_hp.cc

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
Changes in v2:
- Void using seq_file private field as it seems that we can just simply
  returning fuse_backing_files_seq_state in start() and next()
- Apply some suggestions from Amir Goldstein:
  - Use idr_get_next() for iteration
  - Do fuse_backing_get/put(fb) around dereferencing fb->file
- Update fdinfo of fuse files
- Link to v1: https://lore.kernel.org/r/20250507032926.377076-2-chenlinxuan@uniontech.com

---
Chen Linxuan (3):
      fs: fuse: add const qualifier to fuse_ctl_file_conn_get()
      fs: fuse: add backing_files control file
      fs: fuse: add more information to fdinfo

 fs/fuse/control.c | 138 +++++++++++++++++++++++++++++++++++++++++++++++++++++-
 fs/fuse/file.c    |  34 ++++++++++++++
 fs/fuse/fuse_i.h  |   2 +-
 3 files changed, 171 insertions(+), 3 deletions(-)
---
base-commit: d76bb1ebb5587f66b0f8b8099bfbb44722bc08b3
change-id: 20250508-fusectl-backing-files-6810d290e798

Best regards,
-- 
Chen Linxuan <chenlinxuan@uniontech.com>

