From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH 0/5] Backport statx(..., NULL, AT_EMPTY_PATH, ...)
Date: Wed, 18 Sep 2024 22:03:56 +0800
Message-Id: <20240918-statx-stable-linux-6-1-y-v1-0-364a92b1a34f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMzd6mYC/x2MQQqDMBAAvyJ7dsW1kjZ+pXiIcdUFiZJYiYh/b
 /QyMIeZEwJ74QBNdoLnXYIsLgnlGdjJuJFR+uRQlVVdavpg2MwWb3Yz4yzuF1Eh4YGvNytrlCa
 rO0j56nmQ+Ky/sKuCoL2uP9b9yqpwAAAA
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1757;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=nbdCCOPAmbbOfYquegg2cWGUvC5cAPuWKrmvcNQ2fJ0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t3Ul9gTDTMIDlzlk0KI6aMMkSbJbDh9jSddv
 i637cz1O7WJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurd1AAKCRCwMePKe/7Z
 bkquD/wIgINwB5xWq7oqdxIGHHyfUVpjn/pBXPntaU7Vu+uk9+zGC7zGK1L7Sj8AUnHnV3dll6t
 MaigtPkZvBE54cCzPFA4gb48xxo+KGRlirZdgKMsdGvj0dAdp2HTDrtd1cE7A0O+lXbaq8mRQdH
 xcF8kNTyEKni3syz1bZI0JpksNNL5yUT6EgZ01qv/Uuvtn/WEE/hrnLegEpd6KIiWLXTCOZ820v
 M6qg2vxFPq6XqadrWQG09ZuIOGmzLWCblki3fr9hvgnwuzmGnri6VYXGF5XlOELt6J54wNmyFjz
 kHww6lhAjo8EF2QvATRdR10we+suORJrbeWAtDzjBrlK4ilq7sq6NL4BU70sav/PT6MNFnTz4DA
 bWmsOhzBhDJYvrf1jtYrRfiEhPyEkaEVPjYgaZpdjvWdLRxjo4ltULpbqn/BAaw+iIJT3VfLP95
 FcoAH/OwZ43oyngThbb4rBlI+kbsmqK29fRhh5eswCOG7+nMdyImv9ylUrTflP6P8mLanQHCCYV
 u7K7M1no7Vq8q2mEHvk18An3Co8/e21MH40uRrnP/62MucP7j0bfySuzWPTsucOGsO0B68KFywd
 Sn+xGa1BRxWvg4Pp6Y23vFB9K1HBgfE0yHl+9CiU8kwTgxxhhQzjN/MoZYABNaXnoc2Dy6ArUut
 kIaK8Fj23GWimJA==
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
different in 6.1, the content of vfs_statx_path() is modified to match
this. The original patch also moved path_mounted() from namespace.c to
internal.h, which is not applicable for 6.1 since it has not been
introduced before 6.5.

Tested-by: Xi Ruoyao <xry111@xry111.site>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Christian Brauner (3):
      file: add fd_raw cleanup class
      fs: new helper vfs_empty_path()
      stat: use vfs_empty_path() helper

Linus Torvalds (1):
      vfs: mostly undo glibc turning 'fstat()' into 'fstatat(AT_EMPTY_PATH)'

Mateusz Guzik (1):
      vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)

 fs/internal.h        |   2 +
 fs/stat.c            | 101 ++++++++++++++++++++++++++++++++++++++++-----------
 include/linux/file.h |   1 +
 include/linux/fs.h   |  17 +++++++++
 4 files changed, 99 insertions(+), 22 deletions(-)
---
base-commit: 5f55cad62cc9d8d29dd3556e0243b14355725ffb
change-id: 20240918-statx-stable-linux-6-1-y-37e6ca691c9b

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

