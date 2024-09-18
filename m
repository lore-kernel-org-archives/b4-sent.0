From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH 0/3] Backport statx(..., NULL, AT_EMPTY_PATH, ...)
Date: Wed, 18 Sep 2024 22:01:18 +0800
Message-Id: <20240918-statx-stable-linux-6-10-y-v1-0-8364a071074f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAC7d6mYC/x2M0Q5EMBAAf0X22UrXieJXxIOr5TaRnrRIRfy78
 jLJPMyc4NkJe2iSExzv4uVvo1CagPn1dmKUITrkKi9UTRX6tV/Dw+/MOIvdApZICg8kbT5sdFF
 rU0HsF8ejhPfdwl5mpKC7rhtguFJ8cgAAAA==
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Jan Kara <jack@suse.cz>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1261;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=Gqo/olFf/TqaNzYStJ4h4iSgp/m9SF1eYLZDSlE6sec=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t1K3ccq23E7ZBFaXcjel3XM1t9hHB7i4wcQW
 DHQaHvjZCeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurdSgAKCRCwMePKe/7Z
 bqqAD/9mFnhmtbaWcLZxM02VcGsraDoJF/L1Ix/DNiwMxjuGZCqdjDZLmzMSvDYwdMnXrGA48O7
 Jg5PJxqTecHodyF0sF8lAW2NRUkPHo/ABLRmkkDf9xvS3lV2RkW4hqBaXoCZGd9BHM7IZw4RUm9
 euiXHFQ6hjaKRlj4efAi5zf0O7yI4bgvo7tNsFE6j/WaITzZ03tb7Fq8YXaeMjVdlJuZhas5KgC
 BUGGrtm9lwkpXfseosEvDKfEr+oxl0DfGzXn7fcQ5bt9w4uQTlFzzjj9iFz7vmWmUJhxCQztX3v
 bcdOdWxRnzBDNeYrYOnGNn2vi+RjgPIUeZjuZob4cRo27N71yJwPBTVXWASglVNY5lcbxiuUtAk
 0QGSEXsxlEWh1L0jD9k704StspBOnn1y9QXc02vzqns/8QTOzZHIs/VLRlmTANmicQ3P1YGAhlN
 LUG/gLinXqzcYbaExAl18TjEnomMVHoch9Wm8whPBaBSIMdOinZPHHp4H5de0VAngpI87HrqlEI
 oYNtgvLIycHzpS8F9zUswLPQSnzurQUd9OlBC1fbpLUDiP3GaUgbmVwidHU4khcyiTlgFqNQSg2
 MvcvF76G7xFmCCCXZK15MKeHqtNDBN12Y8pP9y/G6MRd2Tx/mOplubimhlKjamnYB3/I8+Y9ERa
 zxIikM6a1A0OXpA==
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

This series is based on the commits in the Linus’ tree. Sligth
modifications are applied to the context of the patches for cleanly
applying.

Tested-by: Xi Ruoyao <xry111@xry111.site>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Christian Brauner (2):
      fs: new helper vfs_empty_path()
      stat: use vfs_empty_path() helper

Mateusz Guzik (1):
      vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)

 fs/internal.h      |  14 ++++++
 fs/namespace.c     |  13 ------
 fs/stat.c          | 123 ++++++++++++++++++++++++++++++++++++-----------------
 include/linux/fs.h |  17 ++++++++
 4 files changed, 116 insertions(+), 51 deletions(-)
---
base-commit: 049be94099ea5ba8338526c5a4f4f404b9dcaf54
change-id: 20240918-statx-stable-linux-6-10-y-17c3ec7497c8

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

