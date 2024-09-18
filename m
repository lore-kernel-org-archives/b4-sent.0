From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH 0/4] Backport statx(..., NULL, AT_EMPTY_PATH, ...)
Date: Wed, 18 Sep 2024 22:02:49 +0800
Message-Id: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAInd6mYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDS0ML3eKSxJIKEJmUk6qbk5lXWqFrBoSVugZGpmZmSZYmJiYGKUpA7QV
 FqWmZFWCjo5XKzPTMlGJrawGEgZPicAAAAA==
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>, stable@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1542;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=u1NNOILc5RCRUZrXoAg9m4Ez2R3H0py30tuyAt5XKOc=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t2MU3kC0Z6qnF1Ftmyh/yEt1BsXOnSiqzwVn
 SHu+uq2CZ2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurdjAAKCRCwMePKe/7Z
 biLGD/4kb/QIvGX3qhukBGiMXQo1AYtpanS80OJfLivzZC0fTA8hHuvfLQEuv15dir40S7GJ5Je
 TnlJrTYh8Vcec/06ILoQIwC3OEyEDMIpI/sb4HOr0drkuTBP0VsYirg3YXuAYllPRYBM1EofaPM
 LxWFvjkM2vFMgF+bYJaOmSq83atXNDYSWc/KhAhepWJf40UPx/AW8/YkkT5t3Sv2q0DBnNNond1
 7d4TbKqPZlR7Aq4pcguNYtMZeASvCoEWHFSQIhUq4VTMc4FJuKvPwt0S3zr4asmJg1m7RMMsJFV
 Q9/cclmd/2sbzrpMImGdDD4j7k+42xAn4d7TZkYOzsuIenjtbUrdplePHlGESH/pxPbi6VN4RVK
 NRNvogXqCvIOw4BLcgCmN6zjTpRFJ0U7JOjLSgag1Akj/GuDCEx1gEnrjLcpjh2mZk2KG5Bc2Is
 DsbbP+PcSLM48niEmcVZKPc//2gpJMgeRSnWus3RZhDnCBUrC5qaDw36o46a+AXP5nWO2uzRJ0I
 bIj5L/c5MddFTTXmyfcAxiEhQs7r7yvi+MEquv1er6koip63T61cITxPt73R5Pkac35LeYvyEqn
 79+ZDzMiV+Va7ItH/ju5aAHBchjz+NGaGjZP9/9ry0kwSW5xmAhaY8VCNUROP9K6U2q3gvnwb9T
 i0Sy9j0/yAJC1YA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 0ef625bba6fb ("vfs: support statx(..., NULL, AT_EMPTY_PATH,
...)") added support for passing in NULL when AT_EMPTY_PATH is given,
improving performance when statx is used for fetching stat informantion
from a given fd, which is especially important for 32-bit platforms.
This commit also improved the performance when an empty string is given
by short-circuiting the handling of such paths.

This series is based on the commits in the Linus’ tree. Modifications
are applied to vfs_statx_path(). In the original patch, vfs_statx_path()
was created to warp around the call to vfs_getattr() after
filename_lookup() in vfs_statx(). Since the coresponding code is
different in 6.6, the content of vfs_statx_path() is modified to match
this.

Tested-by: Xi Ruoyao <xry111@xry111.site>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Christian Brauner (3):
      file: add fd_raw cleanup class
      fs: new helper vfs_empty_path()
      stat: use vfs_empty_path() helper

Mateusz Guzik (1):
      vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)

 fs/internal.h        |  14 +++++++
 fs/namespace.c       |  13 ------
 fs/stat.c            | 113 ++++++++++++++++++++++++++++++++++++---------------
 include/linux/file.h |   1 +
 include/linux/fs.h   |  17 ++++++++
 5 files changed, 112 insertions(+), 46 deletions(-)
---
base-commit: 6d1dc55b5bab93ef868d223b740d527ee7501063
change-id: 20240918-statx-stable-linux-6-6-y-02566b94440d

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

