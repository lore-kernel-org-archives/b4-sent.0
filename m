From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Subject: [PATCH v2 0/3] docs/translations/pt_BR: process: add
 handling-regressions.rst
Date: Sun, 22 Nov 2026 10:32:14 -0300
Message-Id: <20261122-handling-regressions-v2-0-2557db5ab946@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqEMAxFryJZT6ENKDpXGVxoG2tk6EiiIoh3t
 zrL9/nvHaAkTArv4gChjZV/KQO+CvBjlyIZDpkBLVbOIZo8hi+naISikN5/NU3purK33tY2QFZ
 noYH3J/tp/6xrP5Ff7hac5wWGlHGReAAAAA==
X-Change-ID: 20261122-handling-regressions-951a5b0c080d
To: linux-doc@vger.kernel.org
Cc: Eduardo Pereira Cruz <dreduardocruz@gmail.com>, rdunlap@infradead.org, 
 skhan@linuxfoundation.org, corbet@lwn.net, danielmaraboo@gmail.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354334; l=1676;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=y8odRTxkZ1PHw5d/Qd6sZ8r8xIKCChf09gHxL27hi28=;
 b=PwCpBRXpXLndfzKEotswdUqwoF+gYQv9wtVNyGNDcFHMyOBH0KVsgTwqz6rKescmCdkNdaD0V
 Vo6m3LbN1glDWGgJOAsfPtbJd6MqmuDVMaCyMbyX0aTcgiEs3BxHG8R
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the Brazilian Portuguese translation of
Documentation/process/handling-regressions.rst, the document that
describes what the "no regressions" rule means in practice for
developers.

The translation follows the original file as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps
its structure: section levels, literal blocks, URLs, :ref: roles and the
regzbot commands are preserved verbatim.

It is split in three parts to keep the review tractable. The last patch
also wires the new document into the pt_BR process index.

Changes in v2:
- Use "mantenedor" and "tag", matching the rest of the pt_BR tree.
- Keep the term "flag day" instead of inventing a translation.
- Fix two headings that were merged with, or split across, their
  underline, which broke the section hierarchy.
- Reflow paragraphs as a whole instead of line by line, removing the
  orphan fragments introduced by the first version.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
Eduardo Pereira Cruz (3):
      docs/translations/pt_BR: process: add handling-regressions.rst (1/3)
      docs/translations/pt_BR: process: add handling-regressions.rst (2/3)
      docs/translations/pt_BR: process: add handling-regressions.rst (3/3)

 .../pt_BR/process/handling-regressions.rst         | 1176 ++++++++++++++++++++
 Documentation/translations/pt_BR/process/index.rst |    1 +
 2 files changed, 1177 insertions(+)
---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-handling-regressions-951a5b0c080d

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

