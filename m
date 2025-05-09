From: Chen Linxuan <chenlinxuan@uniontech.com>
Subject: [PATCH v3 0/3] fuse: Expose more information of fuse backing files
 to userspace
Date: Fri, 09 May 2025 14:33:52 +0800
Message-Id: <20250509-fusectl-backing-files-v3-0-393761f9b683@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANChHWgC/3WOwQqDMBBEf0Vy7kq6aqI99T9KDzauutTGkqhYx
 H9vFAql0OMbmDezCE+OyYtTtAhHE3vubYDkEAnTlrYh4CqwQImZzGQO9ejJDB3cSnNn20DNHXl
 Q+VFWWEjSRS5C9+mo5nn3Xq6BW/ZD7177zHTc0o9RywQLVHGitdQKEExLtmM7j6U9jzbcGci0s
 ekfYhNN+F3+d2dCkKCwzlRKWhV5+mta1/UN8btUiPsAAAA=
X-Change-ID: 20250508-fusectl-backing-files-6810d290e798
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Amir Goldstein <amir73il@gmail.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1622;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=WL7UUCkIaxd70i0yTLn1OxmFS6Mp12a6aWHS71LWZB4=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoHaHUhMz/8CHmcC875sPKOKvdbx/+8a0mE3ntX
 1uteYpfm5yJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaB2h1AAKCRB2HuYUOZmu
 i/C/EADTYfQ+L1ZHVLSWskQ/sieLfZTnqYIWmvIOSqOhKQzWQvaW+K2CZLab/QjBK7UUhWSC6JH
 IT98ORN1w2VAZLjFMdArsvwbTCNyn6kJROHMFxAe1SwVe0c7NKZiQQFUQHisw2N7BaAoolS1cOt
 +fAEPhvVs2aqbHKMohmURiUiZsWpMKROSd/T/eoNHILalLOXdxv4ijNASBMY6iAEPfBxvVgHgU2
 icv/BoeA9FgqTgqTZsVcBc1NpXRLG5EVdKYun3fHbBCpQEQgTdMYkQ+6kby7kS9rRrEF+oKhtNp
 860gNFycZnK8mCSfkHysaZZWc4wH5ajPsun2mnlxJdzF2mGEWchzyliVfSe/dCjuYreYaJEAshz
 BdkcK2y6FfOEHokUholgBcmAv71+vq8iGgSW2JnQ2RT4/frvqHPvSd9g7qbEMl1TZSTjqC1MVM0
 TB8X+ED7B3BCmcobwCB4aUkOQrs+nJCjY//taqJlySG+fmB04UlexH3ku/8QqfVg3c9AFxofBtj
 8KwjBQQiWXO5iT0dsarZhebRnAJ3KrSMDL19lJsWjhcE7ihOAj75nuAF9X1MP2eazbIBFCo7vKV
 XLofIUeFyzw3SnPalN+TJ2jlwIL+gxFiZ3x2RpvsJ+WgmwfqW5hqarXGb0f/HgO5Ec06jxacPuN
 NJ4PofMv4UWA5pA==
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
Changes in v3:
- Apply some suggestions from Amir Goldstein
- Link to v2: https://lore.kernel.org/r/20250508-fusectl-backing-files-v2-0-62f564e76984@uniontech.com

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

 fs/fuse/control.c | 157 +++++++++++++++++++++++++++++++++++++++++++++++++-----
 fs/fuse/file.c    |  20 +++++++
 fs/fuse/fuse_i.h  |   2 +-
 3 files changed, 165 insertions(+), 14 deletions(-)
---
base-commit: d76bb1ebb5587f66b0f8b8099bfbb44722bc08b3
change-id: 20250508-fusectl-backing-files-6810d290e798

Best regards,
-- 
Chen Linxuan <chenlinxuan@uniontech.com>

