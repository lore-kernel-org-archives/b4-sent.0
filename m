From: Chen Linxuan <chenlinxuan@uniontech.com>
Subject: [PATCH v2 0/2] Add a documentation for FUSE passthrough
Date: Wed, 07 May 2025 16:42:15 +0800
Message-Id: <20250507-fuse-passthrough-doc-v2-0-ae7c0dd8bba6@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOccG2gC/4WOQQ6CMBBFr0Jm7ZhShAor72FYNMOUdiElHSAaw
 t2tXMDl+8l//+8gnAILdMUOibcgIU4Z9KUA8nYaGcOQGbTStaqVQbcK42xFFp/iOnocImHdckn
 3W6VtU0GuzoldeJ/aZ5/ZB1li+pwrW/lL/wi3EhUSqcY605LR+rFO+dnC5K8UX9Afx/EF8xcvO
 LwAAAA=
X-Change-ID: 20250507-fuse-passthrough-doc-59e1c8432a63
To: Miklos Szeredi <miklos@szeredi.hu>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>, 
 Amir Goldstein <amir73il@gmail.com>, 
 Bernd Schubert <bernd.schubert@fastmail.fm>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1186;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=/R+75EXS++vi//z+1SE3h0ZzDGQB+HQ9Cv8vh4zOTX8=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoGxz08UAUIZR6/4SH1If+HbA3AraI/ye151KBQ
 oserKHb6WqJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBsc9AAKCRB2HuYUOZmu
 i4foEAC9iKIDp/SNoaR4Oy+tAn6abLtNXfzF+xrs1TAxhpPfOVL7kv5IdTQqryJVDg5U7wlt3zK
 Oex4unqgJt+jjjcQHvddqoVhODYcIcvDTrAiR9DN9SrvIGzZOA9qoFcWeU64p+yRKgr7VLU/XQN
 4Vtj7gdgM3+fe6HRcSZNq/zHG31Rq+1jyTuGnOw/eXMMaJ0KtxWIzZLcPRkXMXFPs3EOFuhGTYf
 P1m/5fU5A7HksXF/0+E20jbsf90yUQjS+wY2xEiLcZoGWAFgQ2QzyGszQOA53OB0GS6aWB0eONo
 kcR2Myxx1D1H8H7D6C1/atombXmg58hdlb9MHyzaC9F6G0J9UV140RyZ+H63MGhV7hn3BPO7Bqo
 2A7LCbyHMLMIGDffKO2021AK79/0Pi6moyizRssu/fOrGIdFBtpcShyKNeCxM0r5jAGs+vn/X2z
 k8PwWjnatpFEOWx36D+A0PMnZYO6sLjQM3gPa4E/NK4beBTBjI8pZFZLnq3WxeuUW1u9vZ5E/xY
 qeYQT4a0Qq5o5rYLlAoP9caENQ1lk79kllLEyDh6lesJffH9Z9iNfxt+jV7vyo+AzL8GeqMFb+j
 n4c02FJAhSCKt0u7bGYxEkDwiP38jHiwFAU2oVG8+N6RH0wP2XWDCyv4tNwM4Bbpd4PehB/5rf8
 8oQJ3BOuKKOYk+w==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a new file,
Documentation/filesystems/fuse-passthrough.rst, which documents why
FUSE passthrough functionality requires CAP_SYS_ADMIN capabilities.

The series also updates the MAINTAINERS file to ensure
scripts/get_maintainer.pl works correctly with FUSE documentation.

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
Changes in v2:
- Add the docs to Documentation/filesystems/index.rst toctree as Bagas
  Sanjaya suggested
- Remove some paragraphs as Amir Goldstein suggested
- Link to v1: https://lore.kernel.org/r/20250507-fuse-passthrough-doc-v1-0-cc06af79c722@uniontech.com

---
Chen Linxuan (2):
      MAINTAINERS: update filter of FUSE documentation
      docs: filesystems: add fuse-passthrough.rst

 Documentation/filesystems/fuse-passthrough.rst | 133 +++++++++++++++++++++++++
 Documentation/filesystems/index.rst            |   1 +
 MAINTAINERS                                    |   2 +-
 3 files changed, 135 insertions(+), 1 deletion(-)
---
base-commit: 0d8d44db295ccad20052d6301ef49ff01fb8ae2d
change-id: 20250507-fuse-passthrough-doc-59e1c8432a63

Best regards,
-- 
Chen Linxuan <chenlinxuan@uniontech.com>

